//
//  FavoritesView.swift
//  Yumibun
//
//  Created by Armin on 24.07.26.
//

import SwiftUI

private let regularGridColumns = [GridItem(.adaptive(minimum: 168), spacing: 16)]

struct FavoritesBrowser: View {
    @EnvironmentObject private var favorites: FavoritesStore

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()

                if favorites.isEmpty {
                    ContentUnavailableView(
                        "No Favorites Yet",
                        systemImage: "heart",
                        description: Text("Tap the heart on any sound to keep it here.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            LazyVGrid(columns: regularGridColumns, spacing: 16) {
                                ForEach(favorites.favoriteSounds) { sound in
                                    SoundCard(sound: sound, showsFavorite: true)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                        .padding(.top, 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)   // ← THIS is the missing piece
            .navigationTitle("Favorites")
            .playerDock()
        }
    }
}
