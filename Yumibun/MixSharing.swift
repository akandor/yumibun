//
//  MixSharing.swift
//  Yumibun
//
//  Builds and parses shareable mix links that match the web app's format:
//  `https://moodist.toepper.rocks/?share=<url-encoded {id: volume}>`.
//
//  Opening such a link on a device with the app installed deep-links straight into
//  the app (via Universal Links / the Associated Domains entitlement). On any other
//  device the very same link just loads the mix on the website.
//

import Foundation

enum MixShare {
    /// The public site that also renders shared mixes when the app isn't installed.
    static let host = "moodist.toepper.rocks"

    /// A share link for the given `{soundID: volume}` map, or `nil` if the mix is empty.
    static func url(for volumes: [String: Double]) -> URL? {
        guard !volumes.isEmpty else { return nil }

        // Mirror the web app: round each volume to two decimals before encoding.
        var object: [String: Double] = [:]
        for (id, volume) in volumes {
            object[id] = (volume * 100).rounded() / 100
        }

        guard
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
            let json = String(data: data, encoding: .utf8),
            // `encodeURIComponent` equivalent so the site decodes it byte-for-byte.
            let encoded = json.addingPercentEncoding(withAllowedCharacters: Self.uriComponentAllowed)
        else { return nil }

        return URL(string: "https://\(host)/?share=\(encoded)")
    }

    /// The shared `{soundID: volume}` map carried by an incoming link, or `nil` if it
    /// carries none. Unknown sound ids are dropped and volumes are clamped to 0...1.
    static func volumes(from url: URL) -> [String: Double]? {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let share = components.queryItems?.first(where: { $0.name == "share" })?.value
        else { return nil }

        // `queryItems` percent-decodes once; the web then runs `decodeURIComponent`
        // again, so allow for a second layer of encoding just in case.
        let json = share.removingPercentEncoding ?? share

        guard
            let data = json.data(using: .utf8),
            let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        var result: [String: Double] = [:]
        for (id, value) in raw {
            guard SoundCatalog.sound(id: id) != nil else { continue }
            guard let number = (value as? NSNumber)?.doubleValue else { continue }
            result[id] = min(1, max(0, number))
        }

        return result.isEmpty ? nil : result
    }

    /// The character set `encodeURIComponent` leaves untouched.
    private static let uriComponentAllowed: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-_.!~*'()")
        return set
    }()
}

extension SoundMixer {
    /// The share link for the current mix, or `nil` when nothing is selected.
    var shareURL: URL? { MixShare.url(for: volumes) }

    /// Replaces the current mix with one received from a shared link and starts playing,
    /// keeping the listener's current master volume.
    func applySharedMix(_ shared: [String: Double]) {
        restore(Preset(name: "Shared Mix", volumes: shared, masterVolume: masterVolume))
        // A shared mix isn't a saved preset, so the player labels it by its sounds.
        clearCurrentPresetName()
    }
}
