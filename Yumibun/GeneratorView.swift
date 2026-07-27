//
//  GeneratorView.swift
//  Yumibun
//
//  Created by Armin on 24.07.26.
//

import SwiftUI

struct GeneratorView: View {
    @State private var type: GeneratorType = .binaural
    @State private var customPreset: GeneratorPreset?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                List {
                    Section {
                        Picker("Type", selection: $type) {
                            Label("Binaural Beats", systemImage: "headphones")
                                .tag(GeneratorType.binaural)
                            Label("Isochronic Tones", systemImage: "waveform.path.ecg")
                                .tag(GeneratorType.isochronic)
                        }
                        .pickerStyle(.segmented)
#if os(macOS)
                        // macOS pins a Picker's label to the leading edge, shoving the
                        // control to the trailing side; hide it and center the segmented
                        // control across the top instead.
                        .labelsHidden()
                        .fixedSize()
                        .frame(maxWidth: .infinity, alignment: .center)
#endif
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    Section {
                        GeneratorRow(
                            preset: .custom,
                            type: type,
                            isCustom: true,
                            onOpen: { customPreset = .custom }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Theme.stroke)
                        .rowHorizontalInsets()

                        ForEach(GeneratorPreset.presets) { preset in
                            GeneratorRow(preset: preset, type: type)
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(Theme.stroke)
                                .rowHorizontalInsets()
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Neuro Sounds")
            .playerDock()
        }
        .sheet(item: $customPreset) { preset in
            GeneratorSheet(type: type, preset: preset)
        }
    }
}

/// The mini-player for a running generator: a pill with a stop button that docks above
/// the normal player bar (or stands alone when no mix is playing) and disappears on stop.
struct GeneratorPill: View {
    @EnvironmentObject private var generator: GeneratorController

    var body: some View {
        if let active = generator.active {
            HStack(spacing: 12) {
                Image(systemName: active.type.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 34, height: 34)
                    .background(Theme.surface, in: Circle())

                VStack(alignment: .leading, spacing: 1) {
                    Text(active.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text(active.type.title)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button { generator.stop() } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(Theme.surface, in: Circle())
                        .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop \(active.name)")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .floatingBarSurface(Capsule())
            .padding(.horizontal, 16)
            // Matches the player bar's bottom gap so the pill clears the tab bar when
            // it's docked on its own (with no bar beneath it).
            .padding(.bottom, 6)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

enum GeneratorType: String, CaseIterable, Identifiable {
    case binaural
    case isochronic
    var id: Self { self }

    var title: String {
        switch self {
        case .binaural: return "Binaural Beats"
        case .isochronic: return "Isochronic Tones"
        }
    }

    var symbol: String {
        switch self {
        case .binaural: return "headphones"
        case .isochronic: return "waveform.path.ecg"
        }
    }

    /// The label for the second frequency field, which differs by generator type.
    var beatLabel: String {
        switch self {
        case .binaural: return "Beat Frequency (Hz)"
        case .isochronic: return "Tone Frequency (Hz)"
        }
    }
}

/// A named brainwave preset. The same five presets apply to both binaural beats
/// and isochronic tones — only the wording of what the beat frequency drives differs.
struct GeneratorPreset: Identifiable {
    let id: String
    let name: String
    let state: String
    /// The beat (binaural) / pulse (isochronic) frequency in Hz. `nil` for Custom.
    let frequency: Double?

    var isCustom: Bool { frequency == nil }

    /// The display name, translated via the in-app language (like `SoundCatalog`). The
    /// stored `name`/`state` are the English source strings that double as catalog keys.
    var localizedName: String { LanguageSettings.localized(name) }

    func subtitle(for type: GeneratorType) -> String {
        guard let frequency else {
            return LanguageSettings.localized("Set your own frequencies")
        }
        let hz = frequency.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(frequency))
            : String(frequency)
        return "\(LanguageSettings.localized(state)) · \(hz) Hz"
    }

    static let presets: [GeneratorPreset] = [
        GeneratorPreset(id: "delta", name: "Delta", state: "Deep Sleep", frequency: 2),
        GeneratorPreset(id: "theta", name: "Theta", state: "Meditation", frequency: 5),
        GeneratorPreset(id: "alpha", name: "Alpha", state: "Relaxation", frequency: 10),
        GeneratorPreset(id: "beta", name: "Beta", state: "Focus", frequency: 20),
        GeneratorPreset(id: "gamma", name: "Gamma", state: "Cognition", frequency: 40),
    ]

    static let custom = GeneratorPreset(id: "custom", name: "Custom", state: "", frequency: nil)
}

private struct GeneratorRow: View {
    let preset: GeneratorPreset
    let type: GeneratorType
    var isCustom: Bool = false
    var onOpen: () -> Void = {}

    @EnvironmentObject private var generator: GeneratorController
    @State private var volume: Double = 0.5

    private var isPlaying: Bool { generator.isPlaying(preset, type: type) }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Tapping the label area plays a preset, or opens the editor for Custom.
                Button(action: isCustom ? onOpen : togglePlay) {
                    HStack(spacing: 12) {
                        Image(systemName: isCustom ? "slider.horizontal.3" : type.symbol)
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 48, height: 48)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(preset.localizedName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                            Text(preset.subtitle(for: type))
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 4)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: togglePlay) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPlaying ? "Stop \(preset.localizedName)" : "Play \(preset.localizedName)")
            }

            // Per-row volume.
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textTertiary)
                Slider(value: $volume, in: 0...1)
                    .tint(Theme.accent)
                Text("\(Int(volume * 100))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 34, alignment: .trailing)
            }
        }
        .padding(.vertical, 8)
        // Live-update the tone while this row is the one playing.
        .onChange(of: volume) { _, newValue in
            if isPlaying { generator.setVolume(newValue) }
        }
    }

    private func togglePlay() {
        generator.toggle(preset, type: type, volume: volume)
    }
}

struct GeneratorSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var generator: GeneratorController
    @State private var type: GeneratorType
    @State private var frequency1: String = "440"
    @State private var frequency2: String

    init(type: GeneratorType = .binaural, preset: GeneratorPreset = .custom) {
        _type = State(initialValue: type)
        _frequency2 = State(initialValue: preset.frequency.map { String(Int($0)) } ?? "10")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                SheetHeader(title: "Custom", subtitle: LocalizedStringKey(type.title))
                    .padding(.top)

                VStack(spacing: 16) {
                    LabeledField(title: "Base Frequency (Hz)", text: $frequency1)
                    LabeledField(title: LocalizedStringKey(type.beatLabel), text: $frequency2)
                }

                SheetActionButton(title: "Done") {
                    storeCustom()
                    dismiss()
                }
            }
            .sheetContentPadding(iPad: isPad)
            .inlineNavigationTitle()
            // Keep the controller's custom frequencies current, and retune live if the
            // Custom tone is already playing (started from its row).
            .onChange(of: frequency1) { _, _ in applyEdit() }
            .onChange(of: frequency2) { _, _ in applyEdit() }
        }
        .sheetCloseButton()
        .glassSheetBackground()
        .presentationDetents(
            isPad ? [.height(420)] : [.medium]
        )
        .presentationDragIndicator(.visible)
    }

    private func applyEdit() {
        storeCustom()
        generator.retuneCustomIfPlaying(type: type)
    }

    private func storeCustom() {
        generator.customCarrier = Double(frequency1) ?? 200
        generator.customBeat = Double(frequency2) ?? 10
    }
}

private struct LabeledField: View {
    let title: LocalizedStringKey
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            TextField("", text: $text)
                .decimalKeyboard()
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(.regularMaterial, in: Capsule())
        }
    }
}
