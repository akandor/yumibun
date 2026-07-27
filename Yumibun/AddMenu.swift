//
//  AddMenu.swift
//  Yumibun
//
//  Created by Armin on 24.07.26.
//

import SwiftUI


/// The shared contents of the player menu — timers plus the add/share/reset control
/// group. Kept separate from the button chrome so both the player bars and the
/// full-screen player present exactly the same items behind their own labels.
struct AddMenuContent: View {
    let onAddPreset: () -> Void
    let onReset: () -> Void
    let onSleep: () -> Void
    let onCountdown: () -> Void
    let onPomodoro: () -> Void
    /// The current mix's share link. `nil` disables the Share item.
    var shareURL: URL? = nil

    var body: some View {
#if os(macOS)
        // macOS menus render top-to-bottom in declared order and don't support the
        // horizontal `ControlGroup` icon row inside a `Menu` (it comes out empty), so
        // give macOS its own layout: the timers in the same visual order the iOS menu
        // shows them, then plain labelled actions in place of the control group.
        Button { onAddPreset() } label: {
            Label("Add to presets", systemImage: "plus.circle.fill")
        }
        if let shareURL {
            ShareLink(item: shareURL) {
                Label("Share", systemImage: "square.and.arrow.up.fill")
            }
        }
        Button(role: .destructive) { onReset() } label: {
            Label("Reset", systemImage: "trash")
        }
        
        Divider()
        
        Button { onSleep() } label: {
            Label("Sleep timer", systemImage: "moon.zzz.fill")
        }
        Button { onCountdown() } label: {
            Label("Countdown timer", systemImage: "timer")
        }
        Button { onPomodoro() } label: {
            Label("Pomodoro", systemImage: "clock.badge.checkmark")
        }
#else
        Section {
            Button { onPomodoro() } label: {
                Label("Pomodoro", systemImage: "clock.badge.checkmark")
            }
            Button { onCountdown() } label: {
                Label("Countdown timer", systemImage: "timer")
            }
            Button { onSleep() } label: {
                Label("Sleep timer", systemImage: "moon.zzz.fill")
            }
        }
        // Image-only labels (no Text) so the fixed-width control group renders just the
        // icons — a menu derives a button's title from its label's text, so omitting the
        // text is the only way to stop the labels showing and truncating at large sizes.
        ControlGroup {
            Button { onAddPreset() } label: {
                Image(systemName: "plus.circle.fill")
            }
            .accessibilityLabel("Add")

            if let shareURL {
                ShareLink(item: shareURL) {
                    Image(systemName: "square.and.arrow.up.fill")
                }
                .accessibilityLabel("Share")
            }

            Button(role: .destructive) { onReset() } label: {
                Image(systemName: "trash")
            }
            .tint(Theme.danger)
            .accessibilityLabel("Reset")
        }
#endif
    }
}

struct AddMenu: View {
    let onAddPreset: () -> Void
    let onReset: () -> Void
    let onSleep: () -> Void
    let onCountdown: () -> Void
    let onPomodoro: () -> Void
    /// The current mix's share link. `nil` disables the Share item.
    var shareURL: URL? = nil

    var body: some View {
        Menu {
            AddMenuContent(
                onAddPreset: onAddPreset,
                onReset: onReset,
                onSleep: onSleep,
                onCountdown: onCountdown,
                onPomodoro: onPomodoro,
                shareURL: shareURL
            )
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(Theme.accent)
                .frame(width: 38, height: 38)
        }
        // Drop the disclosure arrow, and on macOS the surrounding bezel/box too, so the
        // trigger reads as the same bare "•••" glyph it is on iOS.
        .menuIndicator(.hidden)
#if os(macOS)
        .menuStyle(.button)
        .buttonStyle(.plain)
        .fixedSize()
#endif
    }
}
