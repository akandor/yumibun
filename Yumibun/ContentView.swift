//
//  ContentView.swift
//  Yumibun
//
//  Created by Armin on 16.07.26.
//

import Combine
import SwiftUI

// `isPad` / `isPhone` live in Platform.swift so they resolve on macOS too.

/// Whether the expanded player is showing. Shared so any tab's docked mini-player can
/// raise it while `AppRoot` presents it once at the window root — which on macOS lets
/// it fill the whole window (sidebar included) instead of a single tab.
@MainActor
final class PlayerPresentation: ObservableObject {
    @Published var showFullPlayer = false
}

struct ContentView: View {
    // Observed so a change to the accent palette re-runs this body and re-applies the
    // window `.tint`, propagating the new accent to the tab bar and controls live.
    @EnvironmentObject private var appearance: AppearanceSettings
    @StateObject private var mixer: SoundMixer
    @StateObject private var presets = PresetStore()
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var alarm: AlarmSettings
    @StateObject private var timer: TimerController
    @StateObject private var generator = GeneratorController()
    @StateObject private var playerPresentation = PlayerPresentation()

    init() {
        let mixer = SoundMixer()
        let alarm = AlarmSettings()
        _mixer = StateObject(wrappedValue: mixer)
        _alarm = StateObject(wrappedValue: alarm)
        _timer = StateObject(wrappedValue: TimerController(mixer: mixer, alarm: alarm))
    }

    var body: some View {
        AppRoot()
            .environmentObject(mixer)
            .environmentObject(presets)
            .environmentObject(favorites)
            .environmentObject(alarm)
            .environmentObject(timer)
            .environmentObject(generator)
            .environmentObject(playerPresentation)
            .tint(Theme.accent)
            .onAppear {
                print("Device is iPad:", isPad)
                print("Device is iPhone:", isPhone)
            }
    }
}

// MARK: - App shell (sidebar-adaptable tab bar)

private enum AppTab: Hashable {
    case home
    case presets
    case favorites
    case generator
    case settings
    case savedMix(Preset.ID)
}

private struct AppRoot: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var mixer: SoundMixer
    @EnvironmentObject private var presets: PresetStore
    @EnvironmentObject private var timer: TimerController
    @EnvironmentObject private var appearance: AppearanceSettings

    @State private var selectedTab: AppTab = .home
    @State private var selectedCategoryID = SoundCatalog.categories[0].id
    /// A mix received from a shared link, awaiting the user's confirmation to load.
    @State private var incomingMix: [String: Double]?

    private var category: Category {
        SoundCatalog.categories.first { $0.id == selectedCategoryID } ?? SoundCatalog.categories[0]
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                homeTab
            }

            Tab("Presets", systemImage: "music.note.list", value: AppTab.presets) {
                PresetsView()
            }

            Tab("Favorites", systemImage: "heart", value: AppTab.favorites) {
                FavoritesBrowser()
            }

            Tab("Neuro", systemImage: "brain", value: AppTab.generator) {
                GeneratorView()
            }

            if(!isPhone) {
                if !presets.presets.isEmpty {
                    TabSection {
                        ForEach(presets.presets) { preset in
                            Tab(preset.name, systemImage: "music.note", value: AppTab.savedMix(preset.id)) {
                                savedMixTab(preset)
                            }.defaultVisibility(.hidden, for: .tabBar)
                        }
                    } header: {
                        Label("My Presets", systemImage: "waveform")
                    }.defaultVisibility(.hidden, for: .tabBar)
                }
            }

            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
#if os(macOS)
        // The sidebar-adaptable TabView opens its sidebar quite narrow; widen it once
        // on first layout. The user can still drag it to any width afterwards.
        .background(SidebarWidthSetter(width: 230))
#endif
        // A tapped Universal Link (moodist.tpk.pw/?share=...) arrives here; on devices
        // without the app the same link just opens the website instead.
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            if let url = activity.webpageURL { receiveSharedLink(url) }
        }
        .onOpenURL { receiveSharedLink($0) }
        .alert("New Sound Mix", isPresented: sharedMixPresented) {
            Button("Cancel", role: .cancel) { incomingMix = nil }
            Button("Load Mix") {
                if let mix = incomingMix {
                    withAnimation(.snappy(duration: 0.2)) { mixer.applySharedMix(mix) }
                    selectedTab = .home
                }
                incomingMix = nil
            }
        } message: {
            Text(sharedMixMessage)
        }
        .fullPlayerPresentation()
    }

    @ViewBuilder
    private var homeTab: some View {
        switch appearance.homeStyle {
        case .modern: modernHome
        case .simple: simpleHome
        }
    }

    /// The photographic hero layout, used on both regular (iPad/macOS) and compact.
    /// The regular size class already lives inside the TabView's navigation container,
    /// so it isn't wrapped in another `NavigationStack`; compact provides its own.
    @ViewBuilder
    private var modernHome: some View {
        if horizontalSizeClass == .regular {
            CategoryHeroBrowser(selectedCategoryID: $selectedCategoryID, category: category)
                .background(Theme.background)
#if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
#endif
                .playerDock()
        } else {
            NavigationStack {
                CategoryHeroBrowser(selectedCategoryID: $selectedCategoryID, category: category)
                    .background(Theme.background)
#if os(iOS)
                    .toolbar(.hidden, for: .navigationBar)
#endif
                    .playerDock()
            }
        }
    }

    /// The original circular strip + grid layout.
    @ViewBuilder
    private var simpleHome: some View {
        if horizontalSizeClass == .regular {
            CategoryBrowser(selectedCategoryID: $selectedCategoryID, category: category)
                .navigationTitle("Categories")
                .background(Theme.background)
                .playerDock()
        } else {
            NavigationStack {
                ZStack {
                    Theme.background.ignoresSafeArea()
                    VStack(spacing: 0) {
                        CategoryStrip(selectedID: $selectedCategoryID)
                        SoundGrid(category: category)
                    }
                }
                .navigationTitle("Categories")
                .inlineNavigationTitle()
                .toolbar {
                    // A fixed-size title so it doesn't grow with the user's text size.
                    ToolbarItem(placement: .principal) {
                        Text("Categories")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                            .dynamicTypeSize(.large)
                    }
                }
                .playerDock()
            }
        }
    }

    private func savedMixTab(_ preset: Preset) -> some View {
        homeTab
            .onAppear {
                withAnimation(.snappy(duration: 0.2)) { mixer.restore(preset) }
            }
    }

    private func receiveSharedLink(_ url: URL) {
        guard let mix = MixShare.volumes(from: url) else { return }
        incomingMix = mix
    }

    private var sharedMixPresented: Binding<Bool> {
        Binding(get: { incomingMix != nil }, set: { if !$0 { incomingMix = nil } })
    }

    private var sharedMixMessage: String {
        guard let mix = incomingMix else { return "" }
        let labels = SoundCatalog.allSounds
            .filter { mix[$0.id] != nil }
            .map(\.label)
        let list = labels.count > 3
            ? labels.prefix(3).joined(separator: ", ") + " and \(labels.count - 3) more"
            : labels.joined(separator: ", ")
        return "Someone shared a mix with you:\n\(list).\n\nLoad it and replace your current selection?"
    }
}

// MARK: - Sidebar width (macOS)

#if os(macOS)
import AppKit

/// Widens the `.sidebarAdaptable` TabView's sidebar, which SwiftUI exposes no API for.
/// The sidebar is a split-item managed by an `NSSplitViewController`, so the supported
/// lever is its `minimumThickness` — this both sets the opening width (the sidebar
/// starts at its minimum) and stops the labels from truncating. Note the divider can't
/// be dragged narrower than this; that's the trade-off for a controller-managed split.
private struct SidebarWidthSetter: NSViewRepresentable {
    var width: CGFloat = 220

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        attempt(from: view, tries: 15)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private func attempt(from view: NSView, tries: Int) {
        // A real delay (not just a runloop hop): the split view is built a few frames
        // after this representable first mounts.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let sidebar = view.window?.sidebarSplitItem else {
                if tries > 0 { attempt(from: view, tries: tries - 1) }
                return
            }
            sidebar.minimumThickness = width
        }
    }
}

private extension NSWindow {
    /// The first split item of the window's split-view controller — the sidebar.
    var sidebarSplitItem: NSSplitViewItem? {
        // The controller is the managed split view's delegate; fall back to a search.
        let controller = (contentView?.firstSplitView?.delegate as? NSSplitViewController)
            ?? contentViewController?.firstDescendant()
        return controller?.splitViewItems.first
    }
}

private extension NSView {
    /// Depth-first search of the view tree for the first `NSSplitView`.
    var firstSplitView: NSSplitView? {
        if let split = self as? NSSplitView { return split }
        for sub in subviews {
            if let found = sub.firstSplitView { return found }
        }
        return nil
    }
}

private extension NSViewController {
    /// Depth-first search of the view-controller tree for the first controller of type `T`.
    func firstDescendant<T: NSViewController>() -> T? {
        if let match = self as? T { return match }
        for child in children {
            if let found: T = child.firstDescendant() { return found }
        }
        return nil
    }
}
#endif

// MARK: - Saving a mix

/// Drives the "name your preset" alert. Lives here because both the player bar and
/// the full-screen player can start a save.
struct SavePrompt {
    var isPresented = false
    var name = ""

    mutating func begin(with suggestion: String) {
        name = suggestion
        isPresented = true
    }
}


private struct SavePresetAlert: ViewModifier {
    @Binding var prompt: SavePrompt
    let mixer: SoundMixer
    let presets: PresetStore

    func body(content: Content) -> some View {
        content.alert("Save Preset", isPresented: $prompt.isPresented) {
            TextField("Preset name", text: $prompt.name)
            Button("Cancel", role: .cancel) {}
                .tint(Theme.textSecondary)
            Button("Save") {
                let name = prompt.name.trimmingCharacters(in: .whitespacesAndNewlines)
                let final = name.isEmpty ? presets.suggestedName(for: mixer.selectedSounds) : name
                presets.add(mixer.snapshot(named: final))
            }
        } message: {
            Text("Saves the \(mixer.selectedCount) selected sounds and their volumes.")
        }
    }
}

extension View {
    func savePresetAlert(prompt: Binding<SavePrompt>, mixer: SoundMixer, presets: PresetStore) -> some View {
        modifier(SavePresetAlert(prompt: prompt, mixer: mixer, presets: presets))
    }
}

// MARK: - Full player presentation

/// Presents the expanded player. iOS gets a full-screen cover; macOS has no such
/// presentation, so it's a full-window overlay raised over the whole `TabView`
/// (sidebar included) with a matching slide-up transition.
private struct FullPlayerPresentation: ViewModifier {
    @EnvironmentObject private var mixer: SoundMixer
    @EnvironmentObject private var presets: PresetStore
    @EnvironmentObject private var timer: TimerController
    @EnvironmentObject private var playerPresentation: PlayerPresentation

    func body(content: Content) -> some View {
#if os(macOS)
        content.overlay {
            if playerPresentation.showFullPlayer {
                FullPlayerView(onClose: { playerPresentation.showFullPlayer = false })
                    .environmentObject(mixer)
                    .environmentObject(presets)
                    .environmentObject(timer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.3), value: playerPresentation.showFullPlayer)
#else
        content.fullScreenCover(isPresented: $playerPresentation.showFullPlayer) {
            FullPlayerView()
                .environmentObject(mixer)
                .environmentObject(presets)
                .environmentObject(timer)
        }
#endif
    }
}

extension View {
    func fullPlayerPresentation() -> some View {
        modifier(FullPlayerPresentation())
    }
}

// MARK: - Player dock

/// Docks the mini-player above a tab's content, like Apple Music. It's applied *inside*
/// each tab's `NavigationStack` so the bar floats above the tab bar and — crucially —
/// its bottom safe-area inset reaches the scroll view within the stack, keeping content
/// clear of the bar. It also owns the presentations the bar can trigger (full player,
/// save prompt, timer sheets), so every tab can raise them. The bar renders nothing
/// until a mix is playing, so idle tabs get a zero-height inset.
private struct PlayerDock: ViewModifier {
    @EnvironmentObject private var mixer: SoundMixer
    @EnvironmentObject private var presets: PresetStore
    @EnvironmentObject private var timer: TimerController
    @EnvironmentObject private var generator: GeneratorController
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var playerPresentation: PlayerPresentation

    @State private var savePrompt = SavePrompt()
    @State private var activeTimerSheet: TimerSheet?

    private enum TimerSheet: Identifiable {
        case sleep, countdown, pomodoro
        var id: Self { self }
    }

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) { dock }
            .savePresetAlert(prompt: $savePrompt, mixer: mixer, presets: presets)
            .sheet(item: $activeTimerSheet) { sheet in
                switch sheet {
                case .sleep:
                    SleepTimerSheet { timer.start(.sleep, duration: $0) }
                case .countdown:
                    CountdownTimerSheet { timer.start(.countdown, duration: $0) }
                case .pomodoro:
                    PomodoroTimerSheet { timer.start(.pomodoro, duration: $0) }
                }
            }
    }

    /// The generator pill (when a tone is playing) stacked above the mix player bar, so
    /// a running generator floats over the normal bar — or stands alone when no mix plays.
    private var dock: some View {
        VStack(spacing: 2) {
            GeneratorPill()
            bar
        }
        .animation(.snappy(duration: 0.25), value: generator.active)
        .animation(.snappy(duration: 0.25), value: mixer.hasSelection)
    }

    @ViewBuilder
    private var bar: some View {
        if horizontalSizeClass == .regular {
            WidePlayerBar(
                onExpand: { playerPresentation.showFullPlayer = true },
                onAddPreset: startSave,
                onOpenPresets: {},
                onSleepTimer: { activeTimerSheet = .sleep },
                onCountdownTimer: { activeTimerSheet = .countdown },
                onPomodoroTimer: { activeTimerSheet = .pomodoro }
            )
        } else {
            PlayerBar(
                onExpand: { playerPresentation.showFullPlayer = true },
                onSave: startSave,
                onSleepTimer: { activeTimerSheet = .sleep },
                onCountdownTimer: { activeTimerSheet = .countdown },
                onPomodoroTimer: { activeTimerSheet = .pomodoro }
            )
        }
    }

    private func startSave() {
        savePrompt.begin(with: presets.suggestedName(for: mixer.selectedSounds))
    }
}

extension View {
    /// Docks the persistent mini-player beneath this view. Apply it *inside* a tab's
    /// `NavigationStack`, on the stack's root content. Expanding the player is routed
    /// through the shared `PlayerPresentation` so `AppRoot` can raise it window-wide.
    func playerDock() -> some View { modifier(PlayerDock()) }
}

#Preview {
    ContentView()
        .environmentObject(AppearanceSettings())
        .environmentObject(LanguageSettings())
}
