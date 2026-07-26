//
//  ToneGenerator.swift
//  Moodist
//
//  Synthesizes binaural beats and isochronic tones and exposes a small controller the
//  UI drives. It runs on its own AVAudioEngine, so a generator can play alone or layered
//  on top of the SoundMixer's ambient loops — the system mixes both to the output.
//

import AVFoundation
import Combine
import SwiftUI

/// Renders the actual samples. Parameters are set on the main thread and read once per
/// render block under a lock; the phase accumulators are touched only on the audio thread.
final class ToneEngine {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let sampleRate: Double = 44_100
    private var isRunning = false

    private let lock = NSLock()
    private var type: GeneratorType = .binaural
    private var carrier: Double = 200
    private var beat: Double = 10
    private var volume: Float = 0.5

    // Audio-thread state.
    private var phaseCarrier = 0.0   // left ear / the single isochronic tone
    private var phaseRight = 0.0     // right ear (binaural only)
    private var pulsePhase = 0.0     // isochronic gate, 0...1 per pulse

    func start(type: GeneratorType, carrier: Double, beat: Double, volume: Double) {
        configure(type: type, carrier: carrier, beat: beat, volume: volume)
        guard !isRunning else { return }
        installNodeIfNeeded()
        do {
            try engine.start()
            isRunning = true
        } catch {
            assertionFailure("Tone engine failed to start: \(error)")
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.pause()
        isRunning = false
    }

    func configure(type: GeneratorType, carrier: Double, beat: Double, volume: Double) {
        lock.lock()
        self.type = type
        self.carrier = carrier
        self.beat = beat
        self.volume = Float(volume)
        lock.unlock()
    }

    func setVolume(_ value: Double) {
        lock.lock()
        volume = Float(value)
        lock.unlock()
    }

    private func installNodeIfNeeded() {
        guard sourceNode == nil else { return }
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)

            self.lock.lock()
            let type = self.type, carrier = self.carrier, beat = self.beat, volume = self.volume
            self.lock.unlock()

            let sr = self.sampleRate
            let twoPi = 2.0 * Double.pi
            let carrierStep = twoPi * carrier / sr

            for frame in 0..<Int(frameCount) {
                var left: Float
                var right: Float

                switch type {
                case .binaural:
                    // A slightly different pitch in each ear; the "beat" is perceived.
                    self.phaseCarrier += carrierStep
                    self.phaseRight += twoPi * (carrier + beat) / sr
                    left = Float(sin(self.phaseCarrier))
                    right = Float(sin(self.phaseRight))
                case .isochronic:
                    // A single tone amplitude-gated by a raised cosine at the pulse rate;
                    // the smooth envelope avoids the clicks a hard on/off gate makes.
                    self.phaseCarrier += carrierStep
                    let tone = Float(sin(self.phaseCarrier))
                    self.pulsePhase += beat / sr
                    if self.pulsePhase >= 1 { self.pulsePhase -= 1 }
                    let gate = Float(0.5 - 0.5 * cos(twoPi * self.pulsePhase))
                    left = tone * gate
                    right = left
                }

                if self.phaseCarrier > twoPi { self.phaseCarrier -= twoPi }
                if self.phaseRight > twoPi { self.phaseRight -= twoPi }

                left *= volume
                right *= volume

                for (channel, buffer) in buffers.enumerated() {
                    let samples = buffer.mData!.assumingMemoryBound(to: Float.self)
                    samples[frame] = channel == 0 ? left : right
                }
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        sourceNode = node
    }
}

/// What the UI talks to: which preset is playing (if any), and play/stop/volume.
@MainActor
final class GeneratorController: ObservableObject {
    struct Active: Equatable {
        let id: String
        let name: String
        let type: GeneratorType
    }

    @Published private(set) var active: Active?

    private let engine = ToneEngine()

    /// Binaural presets need a carrier pitch to sit the beat on; the presets only name
    /// the beat frequency, so they share this default base.
    private let defaultCarrier: Double = 200

    /// Last frequencies entered in the custom sheet, reused when Custom is played.
    var customCarrier: Double = 200
    var customBeat: Double = 10

    /// The volume the active tone is playing at, so retuning frequencies keeps it.
    private var lastVolume: Double = 0.5

    var isActive: Bool { active != nil }

    func isPlaying(_ preset: GeneratorPreset, type: GeneratorType) -> Bool {
        active?.id == preset.id && active?.type == type
    }

    /// Toggles a preset: stops it if it's the one already playing, otherwise starts it
    /// (replacing whatever generator was playing — only one runs at a time).
    func toggle(_ preset: GeneratorPreset, type: GeneratorType, volume: Double) {
        if isPlaying(preset, type: type) {
            stop()
        } else {
            play(preset, type: type, volume: volume)
        }
    }

    func play(_ preset: GeneratorPreset, type: GeneratorType, volume: Double) {
        let carrier = preset.isCustom ? customCarrier : defaultCarrier
        let beat = preset.isCustom ? customBeat : (preset.frequency ?? customBeat)
        lastVolume = volume
        active = Active(id: preset.id, name: preset.name, type: type)
        engine.start(type: type, carrier: carrier, beat: beat, volume: volume)
    }

    /// Applies the current custom frequencies to a running Custom tone without changing
    /// its volume — used while editing frequencies in the sheet.
    func retuneCustomIfPlaying(type: GeneratorType) {
        guard isPlaying(.custom, type: type) else { return }
        engine.configure(type: type, carrier: customCarrier, beat: customBeat, volume: lastVolume)
    }

    func setVolume(_ value: Double) {
        lastVolume = value
        engine.setVolume(value)
    }

    func stop() {
        guard active != nil else { return }
        active = nil
        engine.stop()
    }
}
