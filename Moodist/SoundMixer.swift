import AVFoundation
import Combine
import SwiftUI

/// Plays any number of looping sounds at once, each with its own volume.
///
/// Selecting a sound while the mixer is playing starts that loop immediately, so the
/// mix changes live rather than on the next play — matching the web app's behaviour.
@MainActor
final class SoundMixer: ObservableObject {
    /// Volume per selected sound id. Membership here *is* selection.
    @Published private(set) var volumes: [String: Double] = [:]
    @Published private(set) var isPlaying = false

    /// An ordered list of presets to step through with next/previous. Empty when the
    /// current mix wasn't started from "Play All" — the skip controls are inert then.
    @Published private(set) var queue: [Preset] = []
    /// Index into `queue` of the preset currently playing, or nil when there's no queue.
    @Published private(set) var queueIndex: Int?

    /// The name of the preset the current mix was loaded from, so the player shows the
    /// preset's title. Cleared the moment the user hand-edits the selection.
    @Published private(set) var currentPresetName: String?

    /// Scales every sound in the mix. Each player's level is master × its own volume.
    @Published var masterVolume: Double = 0.8 {
        didSet { applyMasterVolume() }
    }

    private var players: [String: AVAudioPlayer] = [:]
    private let nowPlaying = NowPlayingController()

    /// Set when the system interrupts us (call, Siri) so we know whether an
    /// auto-resume is ours to make.
    private var wasPlayingBeforeInterruption = false

    private static let fadeDuration: TimeInterval = 0.25
    private static let defaultVolume: Double = 0.5

    init() {
        configureSession()

        nowPlaying.onPlay = { [weak self] in self?.resumeAll() }
        nowPlaying.onPause = { [weak self] in self?.pauseAll() }
        observeInterruptions()
        refreshNowPlaying()
    }

    // MARK: - Queries

    var selectedIDs: [String] { Array(volumes.keys) }
    var selectedCount: Int { volumes.count }
    var hasSelection: Bool { !volumes.isEmpty }

    /// Whether a "Play All" queue is currently steering the mix.
    var hasQueue: Bool { queueIndex != nil && queue.count > 1 }

    func isSelected(_ sound: Sound) -> Bool { volumes[sound.id] != nil }

    func volume(for sound: Sound) -> Double { volumes[sound.id] ?? Self.defaultVolume }

    /// The sounds currently in the mix, in catalog order, for the player bar's label.
    var selectedSounds: [Sound] {
        SoundCatalog.allSounds.filter { volumes[$0.id] != nil }
    }

    /// Artwork follows the first sound's category, so the player reflects the mix.
    var artworkName: String? { selectedSounds.first?.categoryID }

    var mixTitle: String {
        if let name = currentPresetName { return name }
        let sounds = selectedSounds
        guard let first = sounds.first else { return "Nothing playing" }
        return sounds.count == 1 ? first.label : "\(first.label) + \(sounds.count - 1) more"
    }

    var mixSubtitle: String {
        guard hasSelection else { return "No sounds selected" }
        guard isPlaying else { return "Paused" }
        return "\(selectedCount) sound\(selectedCount == 1 ? "" : "s") playing"
    }

    // MARK: - Selection

    func toggle(_ sound: Sound) {
        if isSelected(sound) {
            deselect(sound)
        } else {
            select(sound)
        }
    }

    func select(_ sound: Sound) {
        guard volumes[sound.id] == nil else { return }
        // Adding a sound by hand means this is no longer the saved preset.
        currentPresetName = nil
        volumes[sound.id] = Self.defaultVolume

        // First sound picked from a stopped mixer starts playback; otherwise the new
        // loop joins the mix already in progress.
        if !isPlaying {
            isPlaying = true
            startAllSelected()
        } else {
            start(sound)
        }
        refreshNowPlaying()
    }

    func deselect(_ sound: Sound) {
        // Removing a sound by hand means this is no longer the saved preset.
        currentPresetName = nil
        volumes[sound.id] = nil
        fadeOutAndStop(id: sound.id)

        if volumes.isEmpty {
            isPlaying = false
        }
        refreshNowPlaying()
    }

    func setVolume(_ value: Double, for sound: Sound) {
        guard volumes[sound.id] != nil else { return }
        volumes[sound.id] = value
        players[sound.id]?.setVolume(level(for: sound.id), fadeDuration: 0)
    }

    func clearAll() {
        clearQueue()
        currentPresetName = nil
        for id in players.keys { fadeOutAndStop(id: id) }
        volumes.removeAll()
        isPlaying = false
        refreshNowPlaying()
    }

    /// Replaces the mix with four random sounds at random volumes and starts playing —
    /// mirrors the web app's shuffle.
    func shuffle() {
        clearQueue()
        currentPresetName = nil
        for id in players.keys { fadeOutAndStop(id: id) }

        let picked = SoundCatalog.allSounds.shuffled().prefix(4)
        guard !picked.isEmpty else {
            volumes.removeAll()
            isPlaying = false
            refreshNowPlaying()
            return
        }

        var next: [String: Double] = [:]
        for sound in picked {
            next[sound.id] = Double.random(in: 0.2...1)
        }
        volumes = next
        isPlaying = true
        startAllSelected()
        refreshNowPlaying()
    }

    // MARK: - Presets

    /// Captures the current mix so it can be restored later.
    func snapshot(named name: String) -> Preset {
        Preset(name: name, volumes: volumes, masterVolume: masterVolume)
    }

    /// Replaces the current mix with a saved preset and starts playing it. Tapping a
    /// preset directly ends any active queue — the user has stepped off the playlist.
    func restore(_ preset: Preset) {
        clearQueue()
        loadMix(from: preset)
    }

    // MARK: - Queue

    /// Starts a playlist: loads the first preset (or the one at `index`) and keeps the
    /// rest queued so next/previous can step through them.
    func playQueue(_ presets: [Preset], startAt index: Int = 0) {
        let ordered = presets.filter { !$0.volumes.isEmpty }
        guard !ordered.isEmpty else { return }
        queue = ordered
        playQueueItem(at: min(max(index, 0), ordered.count - 1))
    }

    /// Advances to the next preset in the queue, wrapping to the start at the end.
    func next() {
        guard let i = queueIndex, !queue.isEmpty else { return }
        playQueueItem(at: (i + 1) % queue.count)
    }

    /// Steps back to the previous preset in the queue, wrapping to the end at the start.
    func previous() {
        guard let i = queueIndex, !queue.isEmpty else { return }
        playQueueItem(at: (i - 1 + queue.count) % queue.count)
    }

    private func playQueueItem(at index: Int) {
        guard queue.indices.contains(index) else { return }
        queueIndex = index
        loadMix(from: queue[index])
    }

    private func clearQueue() {
        queue = []
        queueIndex = nil
    }

    /// Drops the "playing from a preset" label so the mix is titled by its sounds again.
    /// Used for shared mixes, which aren't saved presets.
    func clearCurrentPresetName() {
        currentPresetName = nil
        refreshNowPlaying()
    }

    /// The audio work behind restoring a preset, shared by direct restore and the queue.
    private func loadMix(from preset: Preset) {
        for id in players.keys { fadeOutAndStop(id: id) }
        currentPresetName = preset.name
        volumes = preset.volumes.filter { SoundCatalog.sound(id: $0.key) != nil }
        masterVolume = preset.masterVolume

        guard !volumes.isEmpty else {
            currentPresetName = nil
            isPlaying = false
            refreshNowPlaying()
            return
        }
        isPlaying = true
        startAllSelected()
        refreshNowPlaying()
    }

    private func refreshNowPlaying() {
        nowPlaying.update(
            title: mixTitle,
            subtitle: hasSelection ? mixSubtitle : "",
            artworkName: artworkName,
            isPlaying: isPlaying,
            hasMix: hasSelection
        )
    }

    private func level(for id: String) -> Float {
        Float((volumes[id] ?? Self.defaultVolume) * masterVolume)
    }

    private func applyMasterVolume() {
        guard isPlaying else { return }
        for (id, player) in players {
            player.setVolume(level(for: id), fadeDuration: 0)
        }
    }

    // MARK: - Transport

    func togglePlayPause() {
        guard hasSelection else { return }
        isPlaying ? pauseAll() : resumeAll()
    }

    /// Also the target for the lock screen / Control Centre play button.
    private func resumeAll() {
        guard hasSelection else { return }
#if os(iOS)
        // The session may have been deactivated by an interruption.
        try? AVAudioSession.sharedInstance().setActive(true)
#endif
        isPlaying = true
        startAllSelected()
        refreshNowPlaying()
    }

    private func pauseAll() {
        isPlaying = false
        refreshNowPlaying()
        for (id, player) in players {
            player.setVolume(0, fadeDuration: Self.fadeDuration)
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.fadeDuration) { [weak self] in
                // A resume may have landed during the fade; leave it playing if so.
                guard let self, !self.isPlaying else { return }
                player.pause()
                player.volume = self.level(for: id)
            }
        }
    }

    private func startAllSelected() {
        for sound in selectedSounds { start(sound) }
    }

    // MARK: - Players

    private func start(_ sound: Sound) {
        guard let player = player(for: sound) else { return }

        player.numberOfLoops = -1
        if !player.isPlaying {
            player.volume = 0
            player.play()
        }
        player.setVolume(level(for: sound.id), fadeDuration: Self.fadeDuration)
    }

    private func fadeOutAndStop(id: String) {
        guard let player = players[id] else { return }
        player.setVolume(0, fadeDuration: Self.fadeDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.fadeDuration) { [weak self] in
            player.stop()
            player.currentTime = 0
            self?.players[id] = nil
        }
    }

    private func player(for sound: Sound) -> AVAudioPlayer? {
        if let existing = players[sound.id] { return existing }
        guard let url = sound.url else {
            assertionFailure("Missing bundled audio for \(sound.id)")
            return nil
        }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.numberOfLoops = -1
        player.prepareToPlay()
        players[sound.id] = player
        return player
    }

    private func configureSession() {
#if os(iOS)
        let session = AVAudioSession.sharedInstance()
        // .playback keeps the mix going with the app backgrounded or the screen
        // locked, and routes the hardware volume buttons to it.
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
#endif
        // macOS needs no audio session; AVAudioPlayer just plays.
    }

    /// Phone calls, Siri and other apps' audio interrupt us; resume only if the
    /// system says we may and we were playing when it started.
    private func observeInterruptions() {
#if os(iOS)
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw)
            else { return }

            MainActor.assumeIsolated {
                guard let self else { return }
                switch type {
                case .began:
                    self.wasPlayingBeforeInterruption = self.isPlaying
                    if self.isPlaying { self.pauseAll() }
                case .ended:
                    let options = (note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt)
                        .map(AVAudioSession.InterruptionOptions.init(rawValue:)) ?? []
                    if options.contains(.shouldResume), self.wasPlayingBeforeInterruption {
                        self.resumeAll()
                    }
                    self.wasPlayingBeforeInterruption = false
                @unknown default:
                    break
                }
            }
        }
#endif
        // macOS delivers no AVAudioSession interruptions; nothing to observe.
    }
}
