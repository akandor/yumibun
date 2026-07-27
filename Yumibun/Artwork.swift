import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
typealias PlatformImage = NSImage
#endif

/// Loads the bundled category artwork.
///
/// The synchronized Artwork group flattens the images to the bundle root, so they
/// are not in an asset catalog and `Image(name)` won't find them.
enum Artwork {
    private static let cache = NSCache<NSString, PlatformImage>()

    static func image(named name: String) -> Image? {
        guard let image = platformImage(named: name) else { return nil }
#if canImport(UIKit)
        return Image(uiImage: image)
#elseif canImport(AppKit)
        return Image(nsImage: image)
#endif
    }

    static func platformImage(named name: String) -> PlatformImage? {
        if let hit = cache.object(forKey: name as NSString) { return hit }
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg") else { return nil }
#if canImport(UIKit)
        let image = UIImage(contentsOfFile: url.path)
#elseif canImport(AppKit)
        let image = NSImage(contentsOf: url)
#endif
        guard let image = image else { return nil }
        cache.setObject(image, forKey: name as NSString)
        return image
    }
}

/// Square artwork thumbnail — centre-cropped, never distorted.
///
/// `scaledToFill` grows the image's layout frame past the size it is offered, so a
/// bare `.frame` + `clipShape` would clip to that *larger* frame and render wide.
/// The explicit frame plus `clipped()` is what actually pins it to a square.
struct ArtworkThumbnail: View {
    let name: String?
    var symbol: String = "waveform"
    var size: CGFloat
    var cornerRadius: CGFloat = 10

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        ArtworkView(name: name, symbol: symbol)
            .frame(width: size, height: size)
            .clipped()
            .clipShape(shape)
            .overlay(shape.strokeBorder(Theme.stroke, lineWidth: 1))
    }
}

/// Category artwork with a themed fallback, so a missing file degrades quietly
/// instead of leaving a hole in the layout.
struct ArtworkView: View {
    let name: String?
    var symbol: String = "waveform"

    var body: some View {
        if let name, let image = Artwork.image(named: name) {
            image
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [Theme.surfaceRaised, Theme.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }
}
