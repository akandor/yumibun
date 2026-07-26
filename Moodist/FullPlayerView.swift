//
//  FullPlayerView.swift
//  Moodist
//
//  Created by Armin on 24.07.26.
//

import SwiftUI

struct FullPlayerView: View {
    /// Dismissal path. On iOS the view is a sheet/cover and uses the environment's
    /// `dismiss`; on macOS it's presented as a full-window overlay, which has no
    /// `dismiss`, so the presenter passes an explicit closer here.
    var onClose: (() -> Void)? = nil

    @EnvironmentObject private var mixer: SoundMixer
    @EnvironmentObject private var presets: PresetStore
    @EnvironmentObject private var timer: TimerController
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private func close() {
        if let onClose { onClose() } else { dismiss() }
    }

    @State private var savePrompt = SavePrompt()
    @State private var activeTimerSheet: TimerSheet?

    private enum TimerSheet: Identifiable {
        case sleep, countdown, pomodoro
        var id: Self { self }
    }

    /// A light wash hides the artwork faster than a dark one does — same photo, but
    /// it pales towards the background instead of sinking into it. Light needs the
    /// thinner scrim to keep the image readable behind the controls.
    private var scrimOpacities: [Double] {
        colorScheme == .dark ? [0.35, 0.75, 0.98] : [0.15, 0.55, 0.92]
    }

    var body: some View {
        ZStack {
            // scaledToFill would otherwise size the ZStack to the image's natural
            // dimensions and push the controls off-screen, so pin it to the container.
            GeometryReader { geo in
                ArtworkView(name: mixer.artworkName, symbol: "waveform")
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: scrimOpacities.map { Theme.background.opacity($0) },
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer()
                VStack(spacing: 16) {
                    titleBlock
                    if timer.isActive {
                        TimerChip()
                    }
                }
                .padding(.bottom, 28)
                MasterVolumeSlider()
                    .padding(.horizontal, 28)
                    .padding(.bottom, 34)
                transport
                    .padding(.bottom, 46)
            }
            .padding(.horizontal, 20)
        }
        .savePresetAlert(prompt: $savePrompt, mixer: mixer, presets: presets)
        .sheet(item: $activeTimerSheet) { sheet in
            switch sheet {
            case .sleep:
                SleepTimerSheet { timer.start(.sleep, duration: $0) }
            case .countdown:
                CountdownTimerSheet { timer.start(.countdown, duration: $0) }
            case .pomodoro:
                PomodoroTimerSheet { timer.start(.pomodoro, duration: $0) }
            }
        }
        // Nothing left to show once the mix is emptied from underneath us.
        .onChange(of: mixer.hasSelection) { _, has in
            if !has { close() }
        }
    }

    private var header: some View {
        HStack {
            circleButton("chevron.down", label: "Close player") { close() }
            Spacer()
            Menu {
                AddMenuContent(
                    onAddPreset: { savePrompt.begin(with: presets.suggestedName(for: mixer.selectedSounds)) },
                    onReset: resetMix,
                    onSleep: { activeTimerSheet = .sleep },
                    onCountdown: { activeTimerSheet = .countdown },
                    onPomodoro: { activeTimerSheet = .pomodoro },
                    shareURL: mixer.shareURL
                )
            } label: {
                circleLabel("ellipsis")
            }
            // Without this the item icons inherit the app's accent tint and come
            // out gold; the toolbar menu is tinted the same way.
            .tint(Theme.textPrimary)
            .menuIndicator(.hidden)
#if os(macOS)
            .menuStyle(.button)
            .buttonStyle(.plain)
            .fixedSize()
#endif
            .accessibilityLabel("Menu")
        }
    }

    /// Resetting the mix also ends any running timer — the sounds it was watching are gone.
    private func resetMix() {
        timer.cancel()
        mixer.clearAll()
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text(mixer.mixTitle)
                .font(.system(size: 34, design: .serif))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(mixer.mixSubtitle)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 12)
    }

    private var transport: some View {
        HStack(spacing: 40) {
            skipButton("backward.fill", label: "Previous preset", action: mixer.previous)

            Button {
                mixer.togglePlayPause()
            } label: {
                ZStack {
                    Circle().fill(Theme.textPrimary)
                    Image(systemName: mixer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Theme.background)
                        .contentTransition(.symbolEffect(.replace))
                }
                .frame(width: 84, height: 84)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(mixer.isPlaying ? "Pause" : "Play")

            skipButton("forward.fill", label: "Next preset", action: mixer.next)
        }
    }

    /// Steps through a "Play All" preset queue; dimmed and inert when none is active.
    private func skipButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(mixer.hasQueue ? 1 : 0.3)
        .disabled(!mixer.hasQueue)
        .accessibilityLabel(label)
    }

    private func circleButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            circleLabel(symbol)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// Shared chrome for the header's button and menu, so they sit as a matched pair.
    private func circleLabel(_ symbol: String) -> some View {
        ZStack {
            Circle().fill(.ultraThinMaterial)
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(width: 40, height: 40)
    }
}
