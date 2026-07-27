//
//  PlayerBar.swift
//  Yumibun
//
//  Created by Armin on 24.07.26.
//

import SwiftUI

// MARK: - Player bar

struct PlayerBar: View {
    let onExpand: () -> Void
    let onSave: () -> Void
    let onSleepTimer: () -> Void
    let onCountdownTimer: () -> Void
    let onPomodoroTimer: () -> Void

    @EnvironmentObject private var mixer: SoundMixer
    @EnvironmentObject private var timer: TimerController

    var body: some View {
        if mixer.hasSelection {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    ArtworkThumbnail(name: mixer.artworkName, size: 52)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(mixer.mixTitle)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                        Text(mixer.mixSubtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)

                        if timer.isActive {
                            TimerChip()
                                .padding(.top, 4)
                        }
                    }

                    Spacer(minLength: 4)

                    AddMenu(
                        onAddPreset: onSave,
                        onReset: resetMix,
                        onSleep: onSleepTimer,
                        onCountdown: onCountdownTimer,
                        onPomodoro: onPomodoroTimer,
                        shareURL: mixer.shareURL
                    )

                    Button {
                        mixer.togglePlayPause()
                    } label: {
                        ZStack {
                            Circle().fill(Theme.textPrimary)
                            Image(systemName: mixer.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.background)
                        }
                        .frame(width: 46, height: 46)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(mixer.isPlaying ? "Pause" : "Play")

                    // Only meaningful while a "Play All" queue is active, so it's hidden otherwise.
                    if mixer.hasQueue {
                        Button {
                            mixer.next()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 38, height: 46)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Next preset")
                    }
                }

                MasterVolumeSlider(compact: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .floatingBarSurface(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            // Only the bar's chrome expands the player; the controls keep their own taps.
            .onTapGesture(perform: onExpand)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    /// Resetting the mix also ends any running timer — the sounds it was watching are gone.
    private func resetMix() {
        timer.cancel()
        mixer.clearAll()
    }
}

// MARK: - Timer chip

/// A compact pill in the player bar. While a timer counts down it shows the remaining
/// time with a ✕ to cancel; once the alarm rings it becomes a prominent "Stop alarm"
/// button so the sound can always be silenced from here.
struct TimerChip: View {
    @EnvironmentObject private var timer: TimerController

    var body: some View {
        if let kind = timer.kind {
            running(kind)
        } else if let kind = timer.ringing {
            ringing(kind)
        }
    }

    private func running(_ kind: TimerController.Kind) -> some View {
        HStack(spacing: 6) {
            Image(systemName: kind.symbol)
                .font(.system(size: 11, weight: .semibold))
            Text(timer.display)
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
            Button(action: timer.cancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(3)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel \(kind.title)")
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.surface))
        .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind.title), \(timer.display) remaining")
    }

    private func ringing(_ kind: TimerController.Kind) -> some View {
        Button(action: timer.cancel) {
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .symbolEffect(.bounce, options: .repeating)
                Text("Stop alarm")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Theme.background)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Theme.accent))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stop \(kind.title) alarm")
    }
}

// MARK: - Wide player bar

struct WidePlayerBar: View {
    let onExpand: () -> Void
    let onAddPreset: () -> Void
    let onOpenPresets: () -> Void
    let onSleepTimer: () -> Void
    let onCountdownTimer: () -> Void
    let onPomodoroTimer: () -> Void

    @EnvironmentObject private var mixer: SoundMixer
    @EnvironmentObject private var timer: TimerController

    var body: some View {
        if mixer.hasSelection {
            HStack(spacing: 18) {
                transport

                ArtworkThumbnail(name: mixer.artworkName, size: 46)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mixer.mixTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text(mixer.mixSubtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                .frame(minWidth: 120, alignment: .leading)

                Spacer(minLength: 12)

                masterVolume
                    .frame(maxWidth: 320)

                Spacer(minLength: 12)

                if timer.isActive {
                    TimerChip()
                }

                AddMenu(
                    onAddPreset: onAddPreset,
                    onReset: resetMix,
                    onSleep: onSleepTimer,
                    onCountdown: onCountdownTimer,
                    onPomodoro: onPomodoroTimer,
                    shareURL: mixer.shareURL
                )
                actionButton("arrow.up.left.and.arrow.down.right", tint: Theme.textSecondary, label: "Expand player", action: onExpand)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .floatingBarSurface(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    /// Resetting the mix also ends any running timer — the sounds it was watching are gone.
    private func resetMix() {
        timer.cancel()
        mixer.clearAll()
    }

    private var transport: some View {
        HStack(spacing: 6) {
            // Skip controls step through a "Play All" preset queue; inert until one is
            // active, since a single ambient mix has nothing to skip to.
            skipButton("backward.fill", label: "Previous preset", action: mixer.previous)
            Button {
                mixer.togglePlayPause()
            } label: {
                ZStack {
                    Circle().fill(Theme.textPrimary)
                    Image(systemName: mixer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.background)
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(width: 46, height: 46)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(mixer.isPlaying ? "Pause" : "Play")
            skipButton("forward.fill", label: "Next preset", action: mixer.next)
        }
    }

    private func skipButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(mixer.hasQueue ? 1 : 0.35)
        .disabled(!mixer.hasQueue)
        .accessibilityLabel(label)
    }

    private var masterVolume: some View {
        HStack(spacing: 10) {
            Image(systemName: volumeIcon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 18)
                .contentTransition(.symbolEffect(.replace))
            Slider(value: $mixer.masterVolume, in: 0...1)
                .tint(Theme.accent)
                .accessibilityLabel("Overall volume")
        }
    }

    private var volumeIcon: String {
        switch mixer.masterVolume {
        case ..<0.01: "speaker.slash.fill"
        case ..<0.5: "speaker.wave.1.fill"
        default: "speaker.wave.2.fill"
        }
    }

    private func actionButton(_ symbol: String, tint: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
