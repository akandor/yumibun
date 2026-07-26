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

                VStack(spacing: 8) {
                    Text("Sleep timer")
                        .font(.title2.bold())

                    Text("Stop sounds after a certain amount of time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: 260)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                HStack(spacing: 0) {

                    Picker("Hours", selection: $hours) {
                        ForEach(0..<24, id: \.self) {
                            Text("\($0) h")
                        }
                    }

                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<60, id: \.self) {
                            Text("\($0) m")
                        }
                    }
                }
                .wheelPicker()
                .frame(height: 180)

                
                Button {
                    let duration = TimeInterval(hours * 3600 + minutes * 60)
                    onStart(duration)
                    dismiss()
                } label: {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Theme.background)
                        .padding(.vertical, 18)
                        .background(
                            hours == 0 && minutes == 0
                            ? Color.gray.opacity(0.4)
                            : Theme.textPrimary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 99))
                }
                .controlSize(.large)
                .disabled(hours == 0 && minutes == 0)
            }
            .sheetContentPadding(iPad: isPad)
            .inlineNavigationTitle()
        }
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

                VStack(spacing: 8) {
                    Text("Countdown timer")
                        .font(.title2.bold())

                    Text("Super simple countdown timer.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                HStack(spacing: 0) {

                    Picker("Hours", selection: $hours) {
                        ForEach(0..<24, id: \.self) {
                            Text("\($0) h")
                        }
                    }

                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<60, id: \.self) {
                            Text("\($0) m")
                        }
                    }
                    
                    Picker("Seconds", selection: $seconds) {
                        ForEach(0..<60, id: \.self) {
                            Text("\($0) s")
                        }
                    }
                }
                .wheelPicker()
                .frame(height: 180)

                Button {
                    let duration = TimeInterval(hours * 3600 + minutes * 60 + seconds)
                    onStart(duration)
                    dismiss()
                } label: {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Theme.background)
                        .padding(.vertical, 18)
                        .background(
                            hours == 0 && minutes == 0 && seconds == 0
                            ? Color.gray.opacity(0.4)
                            : Theme.textPrimary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 99))
                }
                .controlSize(.large)
                .disabled(hours == 0 && minutes == 0 && seconds == 0)
            }
            .sheetContentPadding(iPad: isPad)
            .inlineNavigationTitle()
        }
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

                VStack(spacing: 8) {
                    Text("Pomodoro timer")
                        .font(.title2.bold())

                    Text("Super simple countdown timer.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
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

                HStack(spacing: 0) {

                    Picker("Hours", selection: $hours) {
                        ForEach(0..<24, id: \.self) {
                            Text("\($0) h")
                        }
                    }

                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<60, id: \.self) {
                            Text("\($0) m")
                        }
                    }
                }
                .wheelPicker()
                .frame(height: 160)

                Button {
                    let duration = TimeInterval(hours * 3600 + minutes * 60)
                    onStart(duration)
                    dismiss()
                } label: {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Theme.background)
                        .padding(.vertical, 18)
                        .background(
                            hours == 0 && minutes == 0
                            ? Color.gray.opacity(0.4)
                            : Theme.textPrimary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 99))
                }
                .controlSize(.large)
                .disabled(hours == 0 && minutes == 0)
            }
            .sheetContentPadding(iPad: isPad)
            .inlineNavigationTitle()
        }
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
    }
}

extension View {
    func sheetContentPadding(iPad: Bool) -> some View {
        self
            .padding(.top, iPad ? 80 : 40)
            .padding(.bottom, iPad ? 60 : 30)
            .padding(.horizontal, 20)
    }
}
