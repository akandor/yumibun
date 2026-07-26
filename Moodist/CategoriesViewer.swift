//
//  CategoriesViewer.swift
//  Moodist
//
//  Created by Armin on 24.07.26.
//

import SwiftUI

private let regularGridColumns = [GridItem(.adaptive(minimum: 168), spacing: 16)]

struct CategoryBrowser: View {
    @Binding var selectedCategoryID: String
    let category: Category

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {


                WideCategoryStrip(selectedID: $selectedCategoryID)
                    .padding(.top, 20)

                CategoryHeader(category: category)

                LazyVGrid(columns: regularGridColumns, spacing: 16) {
                    ForEach(category.sounds) { sound in
                        SoundCard(sound: sound, showsFavorite: true)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
    }
}

private struct CategoryHeader: View {
    let category: Category

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().strokeBorder(Theme.stroke, lineWidth: 1)
                Image(systemName: category.symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 62, height: 62)

            Text(category.title)
                .font(.system(.title, design: .serif))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}

private struct WideCategoryStrip: View {
    @Binding var selectedID: String
    @EnvironmentObject private var mixer: SoundMixer

    private let spacing: CGFloat = 12
    private let minCircle: CGFloat = 44
    private let maxCircle: CGFloat = 108
    private let labelAllowance: CGFloat = 30

    var body: some View {
        // + 1 for the leading Shuffle chip, so it's sized and fitted like the categories.
        let count = CGFloat(SoundCatalog.categories.count + 1)

        GeometryReader { geo in
            let fit = (geo.size.width - spacing * (count - 1)) / count
            // Never larger than `fit`, so the row always fits the width; capped so it
            // doesn't turn into giant circles on very wide displays (it centers then).
            let circleSize = max(min(fit, maxCircle), minCircle)

            HStack(alignment: .top, spacing: spacing) {
                ShuffleChip(circleSize: circleSize) { mixer.shuffle() }
                    .frame(width: circleSize + 4)

                ForEach(SoundCatalog.categories) { category in
                    CategoryChip(
                        category: category,
                        isSelected: category.id == selectedID,
                        circleSize: circleSize
                    ) {
                        withAnimation(.snappy(duration: 0.25)) { selectedID = category.id }
                    }
                    .frame(width: circleSize + 4)
                }
            }
            .frame(width: geo.size.width, alignment: .center)
        }
        .frame(height: maxCircle + labelAllowance)
    }
}

struct CategoryStrip: View {
    @Binding var selectedID: String
    @EnvironmentObject private var mixer: SoundMixer

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ShuffleChip { mixer.shuffle() }

                ForEach(SoundCatalog.categories) { category in
                    CategoryChip(
                        category: category,
                        isSelected: category.id == selectedID
                    ) {
                        withAnimation(.snappy(duration: 0.25)) { selectedID = category.id }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}

/// A chip styled like a `CategoryChip` but for the shuffle action — accent-tinted so it
/// reads as an action rather than a selectable category.
private struct ShuffleChip: View {
    /// Matches `CategoryChip`: the regular-width strip scales this up; compact keeps 56.
    var circleSize: CGFloat = 56
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Neutral container (like an unselected category) so it reads as an
                    // action, not a permanently-selected category — the accent icon does
                    // the signalling.
                    Circle().fill(Theme.surface)
                    Circle().strokeBorder(Theme.stroke, lineWidth: 1)
                    Image(systemName: "shuffle")
                        .font(.system(size: circleSize * 0.34, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .frame(width: circleSize, height: circleSize)

                Text("Shuffle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: circleSize + 16, height: 30, alignment: .top)
                    .fixedSize()
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Shuffle sounds")
    }
}

private struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    /// The regular-width strip scales these up to fill the row; compact keeps 56.
    var circleSize: CGFloat = 56
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.accent.opacity(0.16) : Theme.surface)
                    Circle()
                        .strokeBorder(
                            isSelected ? Theme.accent : Theme.stroke,
                            lineWidth: isSelected ? 1.5 : 1
                        )
                    Image(systemName: category.symbol)
                        .font(.system(size: circleSize * 0.34, weight: .medium))
                        .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                }
                .frame(width: circleSize, height: circleSize)

                Text(category.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textTertiary)
                    // CG
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: circleSize + 16, height: 30, alignment: .top)
                    .fixedSize()
            }
        }
        .buttonStyle(.plain)
    }
}

struct SoundGrid: View {
    let category: Category

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                CategoryHeader(category: category)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(category.sounds) { sound in
                        SoundCard(sound: sound, showsFavorite: true)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
}
