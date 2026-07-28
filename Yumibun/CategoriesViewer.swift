//
//  CategoriesViewer.swift
//  Yumibun
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

// MARK: - Hero layout (alternative)

/// A full-bleed alternative to `CategoryStrip` + `CategoryHeader`: a photographic hero
/// header topped with a shuffle button, a pill strip of categories, and the sound grid.
/// Existing components are left untouched — this is a parallel presentation.
struct CategoryHeroBrowser: View {
    @Binding var selectedCategoryID: String
    let category: Category

    @EnvironmentObject private var mixer: SoundMixer
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isRegular: Bool { horizontalSizeClass == .regular }

    /// Regular width mirrors the Simple layout's adaptive grid; compact keeps two
    /// even columns like the original sound grid.
    private var gridColumns: [GridItem] {
        isRegular
            ? [GridItem(.adaptive(minimum: 168), spacing: 16)]
            : Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    }

    private var contentPadding: CGFloat { isRegular ? 28 : 20 }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 18) {
                    CategoryHero(
                        category: category,
                        width: geo.size.width,
                        topInset: geo.safeAreaInsets.top
                    ) {
                        withAnimation(.snappy(duration: 0.25)) { mixer.shuffle() }
                    }

                    CategoryPillStrip(selectedID: $selectedCategoryID)

                    LazyVGrid(columns: gridColumns, spacing: isRegular ? 16 : 12) {
                        ForEach(category.sounds) { sound in
                            SoundCard(sound: sound, showsFavorite: true)
                        }
                    }
                    .padding(.horizontal, contentPadding)
                    .padding(.bottom, 28)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

/// The photographic header: category artwork behind a legibility gradient, with the
/// category badge, title, sound count and a few sample sounds — plus a shuffle button
/// floated top-trailing.
private struct CategoryHero: View {
    let category: Category
    /// Explicit width — `scaledToFill` otherwise grows the layout frame past the screen
    /// (see `ArtworkThumbnail`), pushing the whole scroll content wider than the display.
    let width: CGFloat
    /// The top safe-area inset, folded into the height so the photo bleeds under the
    /// status bar while the content stays clear of it.
    var topInset: CGFloat = 0
    let onShuffle: () -> Void

    private let baseHeight: CGFloat = 300

    private var sampleTags: String {
        category.sounds.prefix(3).map(\.label).joined(separator: "  •  ")
    }

    var body: some View {
        ArtworkView(name: category.artworkName, symbol: category.symbol)
            .frame(width: width, height: baseHeight + topInset)
            .clipped()
            // A dark scrim keeps the text legible over any photo — including bright ones
            // in light mode — independent of the app's background colour.
            .overlay(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.25), .black.opacity(0.62)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            // A separate blend that only touches the very bottom edge, dissolving the
            // photo into the app background. Kept below the text zone so it never washes
            // the title out in light mode.
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.72),
                        .init(color: Theme.background.opacity(0.55), location: 0.9),
                        .init(color: Theme.background, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 10) {
                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                        Circle().fill(Color.black.opacity(0.3))
                        Image(systemName: category.symbol)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Theme.accentPalette.colorOnDark)
                    }
                    .frame(width: 52, height: 52)

                    Text(category.title)
                        .font(.system(size: 46, design: .serif))
                        .foregroundStyle(.white)

                    Text("\(category.sounds.count) relaxing sounds")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.accentPalette.colorOnDark)

                    Text(sampleTags)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.82))
                }
                // Drop shadows give every glyph a dark outline, so the accent line and
                // the white text stay readable even where the photo is bright.
                .shadow(color: .black.opacity(0.55), radius: 6, x: 0, y: 1)
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
            .overlay(alignment: .topTrailing) {
                Button(action: onShuffle) {
                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                        Circle().fill(Color.black.opacity(0.3))
                        Image(systemName: "shuffle")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.35), radius: 5, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .padding(.top, topInset + 8)
                .padding(.trailing, 20)
                .accessibilityLabel("Shuffle sounds")
            }
    }
}

/// The category pills under `CategoryHero`. On compact width they scroll horizontally
/// in a single row; on regular width they wrap into centered rows so nothing runs off
/// a narrow window. Separate from `CategoryStrip` so the circular strip is unaffected.
private struct CategoryPillStrip: View {
    @Binding var selectedID: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            FlowLayout(spacing: 10, rowSpacing: 10) {
                pills
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) { pills }
                    .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private var pills: some View {
        ForEach(SoundCatalog.categories) { category in
            CategoryPill(
                category: category,
                isSelected: category.id == selectedID
            ) {
                withAnimation(.snappy(duration: 0.25)) { selectedID = category.id }
            }
        }
    }
}

/// A wrapping layout that flows its subviews left-to-right, breaking to a new row when
/// the next one won't fit, and centering each row within the available width.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    var rowSpacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = rows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + rowSpacing * CGFloat(max(0, rows.count - 1))
        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = rows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX + (bounds.width - row.width) / 2
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + rowSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let projected = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if !current.indices.isEmpty && projected > maxWidth {
                rows.append(current)
                current = Row(indices: [index], width: size.width, height: size.height)
            } else {
                current.width = projected
                current.height = max(current.height, size.height)
                current.indices.append(index)
            }
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

private struct CategoryPill: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.symbol)
                    .font(.system(size: 15, weight: .medium))
                Text(category.title)
                    .font(.system(size: 15, weight: .medium))
                    .fixedSize()
            }
            .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(isSelected ? Theme.accent.opacity(0.16) : Theme.surface)
            )
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? Theme.accent.opacity(0.5) : Theme.stroke,
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
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
