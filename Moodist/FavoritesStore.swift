import Combine
import Foundation
import SwiftUI

/// Per-sound favorites, surfaced in the regular-width sidebar's "Favorites" view
/// and by the heart on each sound card. Independent of `PresetStore`, which saves
/// whole mixes rather than single sounds.
@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var ids: Set<String> = []

    private let key = "moodist.favoriteSounds"

    init() {
        load()
    }

    var isEmpty: Bool { ids.isEmpty }

    /// Favorited sounds in catalog order, skipping any id no longer in the catalog.
    var favoriteSounds: [Sound] {
        SoundCatalog.allSounds.filter { ids.contains($0.id) }
    }

    func isFavorite(_ sound: Sound) -> Bool { ids.contains(sound.id) }

    func toggle(_ sound: Sound) {
        if ids.contains(sound.id) {
            ids.remove(sound.id)
        } else {
            ids.insert(sound.id)
        }
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String].self, from: data)
        else { return }
        ids = Set(decoded)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(Array(ids)) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
