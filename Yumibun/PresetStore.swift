import Combine
import Foundation
import SwiftUI

/// A saved compilation: which sounds were selected, how loud each was, and the
/// master level at the time of saving.
struct Preset: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    /// Sound id -> that sound's own volume (0...1).
    var volumes: [String: Double]
    var masterVolume: Double
    var createdAt: Date = Date()

    /// Saved sounds in catalog order, skipping any id no longer in the catalog.
    var sounds: [Sound] {
        SoundCatalog.allSounds.filter { volumes[$0.id] != nil }
    }

    /// Artwork follows the first sound's category, so a mix looks like what it mostly is.
    var artworkName: String? { sounds.first?.categoryID }

    var subtitle: String {
        let names = sounds.map(\.label)
        guard let first = names.first else { return "Empty mix" }
        return names.count == 1 ? first : "\(first) + \(names.count - 1) more"
    }
}

@MainActor
final class PresetStore: ObservableObject {
    @Published private(set) var presets: [Preset] = []

    /// Unchanged since the feature was called "favorites" — renaming it would
    /// orphan presets already saved on device.
    private let key = "yumibun.mixFavorites"

    init() {
        load()
    }

    var isEmpty: Bool { presets.isEmpty }

    func add(_ preset: Preset) {
        presets.insert(preset, at: 0)
        persist()
    }

    func remove(_ preset: Preset) {
        presets.removeAll { $0.id == preset.id }
        persist()
    }

    func remove(atOffsets offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
        persist()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        presets.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    /// Nudges a preset one place towards the top. macOS lists have no drag-to-reorder
    /// affordance in this layout, so the context menu drives ordering there.
    func moveUp(_ preset: Preset) {
        guard let i = presets.firstIndex(where: { $0.id == preset.id }), i > 0 else { return }
        presets.move(fromOffsets: IndexSet(integer: i), toOffset: i - 1)
        persist()
    }

    /// Nudges a preset one place towards the bottom.
    func moveDown(_ preset: Preset) {
        guard let i = presets.firstIndex(where: { $0.id == preset.id }), i < presets.count - 1 else { return }
        // `move`'s destination is the index to insert *before*, so i+2 lands it after
        // its current successor.
        presets.move(fromOffsets: IndexSet(integer: i), toOffset: i + 2)
        persist()
    }

    /// Whether the preset has somewhere to go, so the menu can disable dead-end items.
    func canMoveUp(_ preset: Preset) -> Bool {
        (presets.firstIndex(where: { $0.id == preset.id }) ?? 0) > 0
    }

    func canMoveDown(_ preset: Preset) -> Bool {
        guard let i = presets.firstIndex(where: { $0.id == preset.id }) else { return false }
        return i < presets.count - 1
    }

    func rename(_ preset: Preset, to name: String) {
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[index].name = name
        persist()
    }

    /// A default name for the save prompt: the mix's dominant sound.
    func suggestedName(for sounds: [Sound]) -> String {
        guard let first = sounds.first else { return "My Mix" }
        let base = sounds.count == 1 ? first.label : "\(first.label) Mix"
        guard presets.contains(where: { $0.name == base }) else { return base }

        var n = 2
        while presets.contains(where: { $0.name == "\(base) \(n)" }) { n += 1 }
        return "\(base) \(n)"
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Preset].self, from: data)
        else { return }
        presets = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
