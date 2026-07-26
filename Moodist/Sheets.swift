//
//  Sheets.swift
//  Moodist
//
//  Created by Armin on 24.07.26.
//

import SwiftUI

struct SleepTimerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var hours = 0
    @State private var minutes = 30

    var onStart: (TimeInterval) -> Void = { _ in }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                SheetHeader(
                    title: "Sleep timer",
                    subtitle: "Stop sounds after a certain amount of time."
                )
                .padding(.top)

                TimePickers(units: [
                    .init(label: "Hours", suffix: "h", range: 0..<24, selection: $hours),
                    .init(label: "Minutes", suffix: "m", range: 0..<60, selection: $minutes),
                ], wheelHeight: 180)

                SheetActionButton(
                    title: "Start",
                    isEnabled: !(hours == 0 && minutes == 0)
                ) {
                    onStart(TimeInterval(hours * 3600 + minutes * 60))
                    dismiss()
                }
            }
            .sheetContentPadding(iPad: isPad)
            .inlineNavigationTitle()
        }
        .sheetCloseButton()
        .glassSheetBackground()
        .presentationDetents(
            isPad ? [.height(420)] : [.medium]
        )
        .presentationDragIndicator(.visible)
    }
}

struct CountdownTimerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var hours = 0
    @State private var minutes = 0
    @State private var seconds = 0

    var onStart: (TimeInterval) -> Void = { _ in }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                SheetHeader(
                    title: "Countdown timer",
                    subtitle: "Super simple countdown timer."
                )
                .padding(.top)

                TimePickers(units: [
                    .init(label: "Hours", suffix: "h", range: 0..<24, selection: $hours),
                    .init(label: "Minutes", suffix: "m", range: 0..<60, selection: $minutes),
                    .init(label: "Seconds", suffix: "s", range: 0..<60, selection: $seconds),
                ], wheelHeight: 180)

                SheetActionButton(
                    title: "Start",
                    isEnabled: !(hours == 0 && minutes == 0 && seconds == 0)
                ) {
                    onStart(TimeInterval(hours * 3600 + minutes * 60 + seconds))
                    dismiss()
                }
            }
            .sheetContentPadding(iPad: isPad, macWidth: 500)
            .inlineNavigationTitle()
        }
        .sheetCloseButton()
        .glassSheetBackground()
        .presentationDetents(
            isPad ? [.height(420)] : [.medium]
        )
        .presentationDragIndicator(.visible)
    }
}

struct PomodoroTimerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var hours = 0
    @State private var minutes = 0

    var onStart: (TimeInterval) -> Void = { _ in }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                SheetHeader(
                    title: "Pomodoro timer",
                    subtitle: "Super simple countdown timer."
                )
                .padding(.top)

                HStack(spacing: 10) {
                    presetChip("Pomodoro", isSelected: hours == 0 && minutes == 25) {
                        hours = 0; minutes = 25
                    }
                    presetChip("Break", isSelected: hours == 0 && minutes == 5) {
                        hours = 0; minutes = 5
                    }
                    presetChip("Long Break", isSelected: hours == 0 && minutes == 15) {
                        hours = 0; minutes = 15
                    }
                }

                TimePickers(units: [
                    .init(label: "Hours", suffix: "h", range: 0..<24, selection: $hours),
                    .init(label: "Minutes", suffix: "m", range: 0..<60, selection: $minutes),
                ], wheelHeight: 160)

                SheetActionButton(
                    title: "Start",
                    isEnabled: !(hours == 0 && minutes == 0)
                ) {
                    onStart(TimeInterval(hours * 3600 + minutes * 60))
                    dismiss()
                }
            }
            .sheetContentPadding(iPad: isPad)
            .inlineNavigationTitle()
        }
        .sheetCloseButton()
        .glassSheetBackground()
        .presentationDetents(
            isPad ? [.height(470)] : [.medium]
        )
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func presetChip(_ label: LocalizedStringKey, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isSelected ? Theme.surfaceRaised : Theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(isSelected ? Theme.accent.opacity(0.45) : Theme.stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Time pickers

/// The row of time-unit pickers shared by the timer sheets.
///
/// iOS shows the units as side-by-side wheels. macOS has no wheel style, so it lays
/// them out as labeled menu pickers — with the label spaced off its popup, the units
/// spaced from each other, and each popup fixed to its intrinsic width so a crowded row
/// (e.g. Hours / Minutes / Seconds) never truncates a popup to "…".
struct TimePickers: View {
    struct Unit: Identifiable {
        let label: LocalizedStringKey
        let suffix: String
        let range: Range<Int>
        let selection: Binding<Int>

        var id: String { suffix }
    }

    let units: [Unit]
    /// The height the wheels need on iOS; ignored on macOS, where the menus self-size.
    var wheelHeight: CGFloat = 180

    var body: some View {
        #if os(macOS)
        HStack(spacing: 22) {
            ForEach(units) { unit in
                HStack(spacing: 8) {
                    Text(unit.label)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                        .fixedSize()
                    picker(for: unit)
                        .labelsHidden()
                        .fixedSize()
                }
            }
        }
        #else
        HStack(spacing: 0) {
            ForEach(units) { unit in
                picker(for: unit)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: wheelHeight)
        #endif
    }

    private func picker(for unit: Unit) -> some View {
        Picker(unit.label, selection: unit.selection) {
            ForEach(unit.range, id: \.self) { value in
                Text("\(value) \(unit.suffix)")
            }
        }
    }
}

// MARK: - Shared sheet chrome

/// The centered title + description shown at the top of every timer / generator sheet.
/// The title is a notch larger on macOS, where these sheets open in a roomy window and
/// the iOS `.title2` reads too small.
struct SheetHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(sheetTitleFont)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
    }
}

#if os(macOS)
private let sheetTitleFont: Font = .title
#else
private let sheetTitleFont: Font = .title2
#endif

/// The full-width pill button at the bottom of every sheet. `.buttonStyle(.plain)` is
/// what keeps macOS from drawing its default push-button bezel behind the pill.
struct SheetActionButton: View {
    let title: LocalizedStringKey
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .foregroundStyle(Theme.background)
                .padding(.vertical, 16)
                .background(isEnabled ? Theme.textPrimary : Color.gray.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 99))
                .contentShape(RoundedRectangle(cornerRadius: 99))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

extension View {
    /// A close (✕) button pinned to the sheet's top-trailing corner. macOS sheets have
    /// no drag-to-dismiss handle, so they need an explicit control; on iOS the drag
    /// indicator already does the job, so this is a no-op there.
    @ViewBuilder
    func sheetCloseButton() -> some View {
        #if os(macOS)
        self.overlay(alignment: .topTrailing) { SheetCloseButton() }
        #else
        self
        #endif
    }

    /// Swaps the sheet's opaque background for Liquid Glass on OSes that support it
    /// (iOS 26 / macOS 26); older systems keep their default sheet background.
    @ViewBuilder
    func glassSheetBackground() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.presentationBackground {
                Color.clear.glassEffect(.regular, in: Rectangle())
            }
        } else {
            self
        }
    }

    func sheetContentPadding(iPad: Bool, macWidth: CGFloat = 380) -> some View {
        #if os(macOS)
        // macOS sheets size to their content, so keep the padding modest and pin a
        // comfortable width rather than inheriting the iPad's generous insets. Sheets
        // with a busier picker row (e.g. Countdown's H/M/S) pass a wider `macWidth`.
        self
            .padding(.top, 28)
            .padding(.bottom, 28)
            .padding(.horizontal, 32)
            .frame(width: macWidth)
        #else
        self
            .padding(.top, iPad ? 80 : 40)
            .padding(.bottom, iPad ? 60 : 30)
            .padding(.horizontal, 20)
        #endif
    }
}

#if os(macOS)
private struct SheetCloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 28, height: 28)
                .background(Theme.surface, in: Circle())
                .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(14)
    }
}
#endif
