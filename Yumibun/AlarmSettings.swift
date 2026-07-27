import AVFoundation
import Combine
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Volume and vibration for the timer alarm, plus a preview so both can be judged
/// while choosing them. The timers themselves aren't built yet; this is what
/// they'll read.
@MainActor
final class AlarmSettings: ObservableObject {
    @Published var volume: Double {
        didSet {
            UserDefaults.standard.set(volume, forKey: Self.volumeKey)
            player?.volume = Float(volume)
        }
    }

    @Published var vibrationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(vibrationEnabled, forKey: Self.vibrationKey)
            // Let the change be felt right away if it lands mid-preview or mid-alarm.
            if isPreviewing {
                vibrationEnabled ? startHaptics(until: previewEnds) : stopHaptics()
            } else if isRinging {
                vibrationEnabled ? startHaptics(until: .distantFuture) : stopHaptics()
            }
        }
    }

    @Published private(set) var isPreviewing = false
    /// True while a timer alarm is sounding, until the listener dismisses it.
    @Published private(set) var isRinging = false

    private var player: AVAudioPlayer?
    private var hapticsTask: Task<Void, Never>?
    private var previewEnds = Date()

    private static let volumeKey = "yumibun.alarmVolume"
    private static let vibrationKey = "yumibun.alarmVibration"

    init() {
        volume = UserDefaults.standard.object(forKey: Self.volumeKey) as? Double ?? 0.8
        vibrationEnabled = UserDefaults.standard.object(forKey: Self.vibrationKey) as? Bool ?? true
    }

    func togglePreview() {
        isPreviewing ? stopPreview() : startPreview()
    }

    /// Rings the alarm because a countdown/pomodoro timer reached zero. Loops the sound
    /// (and vibration) until `dismiss()`, so a missed alarm doesn't just play once and go
    /// unnoticed. Uses the listener's chosen alarm volume.
    func fire() {
        guard !isRinging else { return }
        stopPreview()            // a lingering preview shouldn't sit under a real alarm
        playAlarm(loop: true)
        isRinging = true
    }

    /// Silences a ringing timer alarm.
    func dismiss() {
        guard isRinging else { return }
        stopAlarm()
        isRinging = false
    }

    // MARK: - Preview

    private func startPreview() {
        playAlarm(loop: false)
        guard let player else { return }
        isPreviewing = true

        let duration = player.duration

        // AVAudioPlayerDelegate would need an NSObject shim for one callback; the
        // clip is short and fixed, so just clear the flag when it's due to end.
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard let self, self.player === player else { return }
            self.stopPreview()
        }
    }

    private func stopPreview() {
        guard isPreviewing else { return }
        stopAlarm()
        isPreviewing = false
    }

    // MARK: - Playback

    private func playAlarm(loop: Bool) {
        stopAlarm()

        guard let url = Bundle.main.url(forResource: "alarm", withExtension: "mp3"),
              let player = try? AVAudioPlayer(contentsOf: url)
        else { return }

        player.volume = Float(volume)
        player.numberOfLoops = loop ? -1 : 0
        player.play()
        self.player = player

        let end = loop ? Date.distantFuture : Date().addingTimeInterval(player.duration)
        previewEnds = end
        if vibrationEnabled { startHaptics(until: end) }
    }

    private func stopAlarm() {
        player?.stop()
        player = nil
        stopHaptics()
    }

    // MARK: - Haptics

    /// Pulses for the length of the preview. Real devices only — the Simulator has
    /// no haptics hardware, so this is silent there.
    private func startHaptics(until end: Date) {
#if os(iOS)
        hapticsTask?.cancel()
        hapticsTask = Task { @MainActor [weak self] in
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()

            while !Task.isCancelled, Date() < end {
                guard let self, self.vibrationEnabled else { return }
                generator.impactOccurred()
                try? await Task.sleep(for: .milliseconds(650))
            }
        }
#endif
        // macOS has no haptics engine; the alarm sound alone signals the timer.
    }

    private func stopHaptics() {
        hapticsTask?.cancel()
        hapticsTask = nil
    }
}
