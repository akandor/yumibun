//
//  SoundCard.swift
//  Yumibun
//
//  Created by Armin on 24.07.26.
//

import SwiftUI

struct SoundCard: View {
    let sound: Sound
    /// The regular-width grid shows a favorite heart; the compact grid doesn't.
    var showsFavorite: Bool = false

    @EnvironmentObject private var mixer: SoundMixer

    private var isSelected: Bool { mixer.isSelected(sound) }
    /// The equalizer only animates while the sound is part of a running mix.
    private var isPlaying: Bool { isSelected && mixer.isPlaying }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isSelected ? Theme.accent.opacity(0.16) : Theme.surface)
                Circle()
                    .strokeBorder(
                        isSelected ? Theme.accent : Theme.stroke,
                        lineWidth: isSelected ? 1.5 : 1
                    )
                if isPlaying {
                    EqualizerWave()
                        .frame(width: 20, height: 16)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                } else {
                    Image(systemName: sound.symbol)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .frame(width: 48, height: 48)
            .animation(.snappy(duration: 0.22), value: isPlaying)

            Text(sound.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 30, alignment: .top)

            VolumeSlider(sound: sound)
                .opacity(isSelected ? 1 : 0.35)
                .disabled(!isSelected)
        }
        .padding(.horizontal, 10)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? Theme.surfaceRaised : Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isSelected ? Theme.accent.opacity(0.45) : Theme.stroke, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            withAnimation(.snappy(duration: 0.22)) { mixer.toggle(sound) }
        }
        // The heart sits above the card, so its own button intercepts the tap
        // before the card's toggle gesture sees it.
        .overlay(alignment: .topTrailing) {
            if showsFavorite {
                FavoriteHeart(sound: sound)
            }
        }
        .accessibilityHint(isSelected ? "Selected. Tap to remove from the mix." : "Tap to add to the mix.")
    }
}

private struct FavoriteHeart: View {
    let sound: Sound

    @EnvironmentObject private var favorites: FavoritesStore

    private var isFavorite: Bool { favorites.isFavorite(sound) }

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { favorites.toggle(sound) }
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isFavorite ? Theme.accent : Theme.textSecondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(6)
        .accessibilityLabel(isFavorite ? "Remove \(sound.label) from favorites" : "Add \(sound.label) to favorites")
    }
}

/// A row of bars that bounce at staggered rates to read as a playing equalizer.
private struct EqualizerWave: View {
    /// Relative rest/peak heights per bar, staggered so the bars never move in unison.
    private let bars: [(min: CGFloat, max: CGFloat, delay: Double)] = [
        (0.30, 0.80, 0.00),
        (0.45, 1.00, 0.18),
        (0.25, 0.70, 0.36),
        (0.50, 0.95, 0.12),
    ]

    @State private var animating = false

    var body: some View {
        GeometryReader { proxy in
            let spacing = proxy.size.width * 0.14
            let barWidth = (proxy.size.width - spacing * CGFloat(bars.count - 1)) / CGFloat(bars.count)

            HStack(alignment: .center, spacing: spacing) {
                ForEach(bars.indices, id: \.self) { index in
                    Capsule()
                        .fill(Theme.accent)
                        .frame(
                            width: barWidth,
                            height: proxy.size.height * (animating ? bars[index].max : bars[index].min)
                        )
                        .animation(
                            .easeInOut(duration: 0.42)
                                .repeatForever(autoreverses: true)
                                .delay(bars[index].delay),
                            value: animating
                        )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .onAppear { animating = true }
    }
}

/// The card owns tap-to-toggle, so this only needs to stay inert while the sound is off.
private struct VolumeSlider: View {
    let sound: Sound

    @EnvironmentObject private var mixer: SoundMixer

    var body: some View {
        MusicSlider(
            value: Binding(
                get: { mixer.volume(for: sound) },
                set: { mixer.setVolume($0, for: sound) }
            )
        )
        .accessibilityLabel("\(sound.label) volume")
    }
}
