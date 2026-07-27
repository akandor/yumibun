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
                Image(systemName: sound.symbol)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
            }
            .frame(width: 56, height: 56)

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

/// The card owns tap-to-toggle, so this only needs to stay inert while the sound is off.
private struct VolumeSlider: View {
    let sound: Sound

    @EnvironmentObject private var mixer: SoundMixer

    var body: some View {
        Slider(
            value: Binding(
                get: { mixer.volume(for: sound) },
                set: { mixer.setVolume($0, for: sound) }
            ),
            in: 0...1
        )
        .controlSize(.mini)
        .tint(Theme.accent)
        .accessibilityLabel("\(sound.label) volume")
    }
}
