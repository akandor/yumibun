import AVFoundation
import MediaPlayer
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Bridges the mixer to the system: lock screen / Control Centre / Dynamic Island
/// controls, and the metadata shown alongside them.
///
/// The mix is an endless set of loops rather than a track, so it is published as a
/// live stream — that hides the scrubber and elapsed-time UI, which would be
/// meaningless here.
@MainActor
final class NowPlayingController {
    var onPlay: (() -> Void)?
    var onPause: (() -> Void)?

    private var isConfigured = false

    func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            guard let self, let onPlay else { return .commandFailed }
            onPlay()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            guard let self, let onPause else { return .commandFailed }
            onPause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            // Headphone/AirPods squeeze sends toggle rather than play or pause.
            if self.isPlayingNow { self.onPause?() } else { self.onPlay?() }
            return .success
        }

        // Nothing to seek or skip in an endless ambient mix.
        for command in [center.nextTrackCommand, center.previousTrackCommand,
                        center.seekForwardCommand, center.seekBackwardCommand,
                        center.changePlaybackPositionCommand] {
            command.isEnabled = false
        }
    }

    private var isPlayingNow = false

    func update(title: String, subtitle: String, artworkName: String?, isPlaying: Bool, hasMix: Bool) {
        configureIfNeeded()
        isPlayingNow = isPlaying

        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = hasMix
        center.pauseCommand.isEnabled = hasMix
        center.togglePlayPauseCommand.isEnabled = hasMix

        guard hasMix else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            MPNowPlayingInfoCenter.default().playbackState = .stopped
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: subtitle,
            MPMediaItemPropertyAlbumTitle: "Moodist",
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]

        if let name = artworkName, let image = Artwork.platformImage(named: name) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }
}
