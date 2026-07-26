//
//  PresetsView.swift
//  Moodist
//
//  Created by Armin on 24.07.26.
//

import SwiftUI

// Matches `rowHorizontalInsets()`: the list rows sit 28pt in on macOS and keep the
// standard 16pt on iOS/iPad, so the "Play All" pill above them follows suit.
#if os(macOS)
private let presetPillInset: CGFloat = 28
#else
private let presetPillInset: CGFloat = 16
#endif

struct PresetsView: View {
    @EnvironmentObject private var mixer: SoundMixer
    @EnvironmentObject private var presets: PresetStore
    @Environment(\.dismiss) private var dismiss

    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    #endif
    @State private var renamingPreset: Preset?
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if presets.isEmpty {
                    ContentUnavailableView(
                        "No Presets Yet",
                        systemImage: "music.note.list",
                        description: Text("Pick some sounds, then tap ... in the player and select 'Add to presets' to save the mix as a preset.")
                    )
                } else {
                    VStack(spacing: 0) {
                        PlayAllButton {
                            mixer.playQueue(presets.presets)
                            // On macOS this view is a persistent sidebar tab, not a
                            // sheet — calling dismiss() there would close the whole
                            // window. Only dismiss where it's actually presented.
                            dismissIfPresented()
                        }
                        // Align the pill with the list rows, which sit further in on macOS.
                        .padding(.horizontal, presetPillInset)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                        List {
                            ForEach(presets.presets) { preset in
                                PresetRow(
                                    preset: preset,
                                    onPlay: {
                                        mixer.restore(preset)
                                        dismissIfPresented()
                                    },
                                    onRename: { beginRename(preset) },
                                    onDelete: { presets.remove(preset) },
                                    onMoveUp: { presets.moveUp(preset) },
                                    onMoveDown: { presets.moveDown(preset) },
                                    canMoveUp: presets.canMoveUp(preset),
                                    canMoveDown: presets.canMoveDown(preset)
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(Theme.stroke)
                                .rowHorizontalInsets()
                            }
                            .onDelete { presets.remove(atOffsets: $0) }
                            .onMove { presets.move(fromOffsets: $0, toOffset: $1) }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("My Presets")
            #if os(iOS)
            .environment(\.editMode, $editMode)
            .toolbar {
                if !presets.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            withAnimation {
                                editMode = editMode.isEditing ? .inactive : .active
                            }
                        } label: {
                            Text(editMode.isEditing ? "Done" : "Edit")
                        }
                    }
                }
            }
            #endif
            .alert("Rename Preset", isPresented: renamePresented) {
                TextField("Preset name", text: $renameText)
                Button("Cancel", role: .cancel) { renamingPreset = nil }
                Button("Save") { commitRename() }
            }
            .playerDock()
        }
    }

    /// Dismisses only on iOS, where Presets can be presented modally. On macOS it's a
    /// sidebar tab with no presenter, so `dismiss()` would close the window instead.
    private func dismissIfPresented() {
        #if os(iOS)
        dismiss()
        #endif
    }

    private var renamePresented: Binding<Bool> {
        Binding(get: { renamingPreset != nil }, set: { if !$0 { renamingPreset = nil } })
    }

    private func beginRename(_ preset: Preset) {
        renameText = preset.name
        renamingPreset = preset
    }

    private func commitRename() {
        guard let preset = renamingPreset else { return }
        let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { presets.rename(preset, to: name) }
        renamingPreset = nil
    }
}

/// The prominent pill above the preset list that queues every preset and starts
/// playing the first, so the whole library can be stepped through with next/previous.
private struct PlayAllButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 17, weight: .bold))
                Text("Play All")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(Theme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Capsule().fill(Theme.accent))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Play all presets")
    }
}

private struct PresetRow: View {
    let preset: Preset
    let onPlay: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    var onMoveUp: () -> Void = {}
    var onMoveDown: () -> Void = {}
    var canMoveUp: Bool = false
    var canMoveDown: Bool = false

    #if os(iOS)
    @Environment(\.editMode) private var editMode
    private var isEditing: Bool { editMode?.wrappedValue.isEditing ?? false }
    #else
    // macOS lists have no edit mode; rows always show the play button, and rename /
    // delete / reorder live in a right-click context menu (there's no swipe or
    // drag-to-reorder in this layout on macOS).
    private var isEditing: Bool { false }
    #endif

    var body: some View {
        rowContent
#if os(macOS)
            .contextMenu {
                Button("Play") { onPlay() }
                Button("Rename") { onRename() }
                Divider()
                Button("Move Up") { onMoveUp() }
                    .disabled(!canMoveUp)
                Button("Move Down") { onMoveDown() }
                    .disabled(!canMoveDown)
                Divider()
                Button("Delete", role: .destructive) { onDelete() }
            }
#endif
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            ArtworkThumbnail(name: preset.artworkName, size: 54)

            VStack(alignment: .leading, spacing: 3) {
                Text(preset.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(preset.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if isEditing {
                // A hint that tapping the row now renames it, rather than plays.
                Image(systemName: "pencil")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 44, height: 44)
            } else {
                // Only this button starts the preset — tapping elsewhere on the row does nothing.
                Button(action: onPlay) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.accent)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Play \(preset.name)")
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        // In edit mode the whole row is the rename target; otherwise taps here are inert.
        .onTapGesture { if isEditing { onRename() } }
    }
}
