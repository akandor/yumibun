//
//  TimerController.swift
//  Moodist
//
//  Drives the active sleep / countdown / pomodoro timer and publishes the remaining
//  time so the player bar can show it live. Sleep timers stop playback when they end;
//  countdown and pomodoro timers ring the alarm and leave the mix playing — matching
//  the web app's behaviour.
//

import Combine
import SwiftUI

@MainActor
final class TimerController: ObservableObject {
    enum Kind: String {
        case sleep
        case countdown
        case pomodoro

        var title: String {
            switch self {
            case .sleep: return "Sleep timer"
            case .countdown: return "Countdown"
            case .pomodoro: return "Pomodoro"
            }
        }

        var symbol: String {
            switch self {
            case .sleep: return "moon.zzz.fill"
            case .countdown: return "timer"
            case .pomodoro: return "clock.badge.checkmark"
            }
        }

        /// Sleep timers fade the mix out at zero; the others ring the alarm instead.
        var stopsPlayback: Bool { self == .sleep }
    }

    @Published private(set) var kind: Kind?
    @Published private(set) var remaining: TimeInterval = 0
    /// The timer whose alarm is currently sounding, if any. Set for countdown/pomodoro
    /// when they reach zero; cleared when the listener stops the alarm.
    @Published private(set) var ringing: Kind?

    /// Whether the player bar should show the timer chip — a timer is counting down or
    /// its alarm is ringing.
    var isActive: Bool { kind != nil || ringing != nil }

    /// mm:ss, or h:mm:ss past an hour, rounded up so the last second shows as 00:01.
    var display: String {
        let total = Int(remaining.rounded(.up))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }

    private unowned let mixer: SoundMixer
    private let alarm: AlarmSettings
    private var ticker: Task<Void, Never>?

    init(mixer: SoundMixer, alarm: AlarmSettings) {
        self.mixer = mixer
        self.alarm = alarm
    }

    func start(_ kind: Kind, duration: TimeInterval) {
        cancel()
        guard duration > 0 else { return }

        self.kind = kind
        remaining = duration
        let end = Date().addingTimeInterval(duration)

        ticker = Task { [weak self] in
            await self?.run(until: end)
        }
    }

    /// Stops the running countdown and silences the alarm if it's ringing. Covers both
    /// the chip's stop button and a mix reset.
    func cancel() {
        ticker?.cancel()
        ticker = nil
        kind = nil
        remaining = 0
        if ringing != nil {
            ringing = nil
            alarm.dismiss()
        }
    }

    /// Recomputes the remaining time from the fixed end date every half-second, so the
    /// display stays accurate even if a tick is delayed (e.g. briefly backgrounded).
    private func run(until end: Date) async {
        while !Task.isCancelled {
            let left = end.timeIntervalSinceNow
            guard left > 0 else { break }
            remaining = left
            try? await Task.sleep(for: .seconds(min(0.5, left)))
        }
        guard !Task.isCancelled else { return }
        fire()
    }

    private func fire() {
        let finished = kind
        ticker = nil
        kind = nil
        remaining = 0

        switch finished {
        case .sleep:
            mixer.clearAll()
        case .countdown, .pomodoro:
            // Keep the chip alive in an "alarm ringing" state so it can be dismissed.
            ringing = finished
            alarm.fire()
        case .none:
            break
        }
    }
}
