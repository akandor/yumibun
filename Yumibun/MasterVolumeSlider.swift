//
//  MasterVolumeSlider.swift
//  Yumibun
//
//  Created by Armin on 24.07.26.
//

import SwiftUI

struct MasterVolumeSlider: View {
    var compact = false

    @EnvironmentObject private var mixer: SoundMixer

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: compact ? 12 : 16))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: compact ? 16 : 44, height: compact ? 16 : 44)
                .background(compact ? nil : Circle().fill(.ultraThinMaterial))
                .contentTransition(.symbolEffect(.replace))

            Slider(value: $mixer.masterVolume, in: 0...1)
                .controlSize(compact ? .mini : .regular)
                .tint(compact ? Theme.accent : Theme.textPrimary)
                .accessibilityLabel("Overall volume")
        }
    }

    private var icon: String {
        switch mixer.masterVolume {
        case ..<0.01: "speaker.slash.fill"
        case ..<0.5: "speaker.wave.1.fill"
        default: "speaker.wave.2.fill"
        }
    }
}
