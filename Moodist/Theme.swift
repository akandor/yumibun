//
//  Theme.swift
//  Moodist
//
//  Created by Armin on 16.07.26.
//

import SwiftUI
import CoreText
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    /// Create a color from a 0xRRGGBB hex literal.
    init(hex: UInt, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    /// Create a color from an "RRGGBB" (or "#RRGGBB") string. Returns nil if unparseable.
    init?(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt(s, radix: 16) else { return nil }
        self.init(hex: value)
    }

    /// The color's "RRGGBB" hex string. Falls back to the accent hex if it can't be resolved.
    func toHexString() -> String {
        let r: CGFloat, g: CGFloat, b: CGFloat
        #if canImport(UIKit)
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        guard UIColor(self).getRed(&rr, green: &gg, blue: &bb, alpha: &aa) else { return "DEAA22" }
        (r, g, b) = (rr, gg, bb)
        #elseif canImport(AppKit)
        guard let ns = NSColor(self).usingColorSpace(.sRGB) else { return "DEAA22" }
        (r, g, b) = (ns.redComponent, ns.greenComponent, ns.blueComponent)
        #else
        return "DEAA22"
        #endif
        func channel(_ v: CGFloat) -> Int { min(255, max(0, Int(round(v * 255)))) }
        return String(format: "%02X%02X%02X", channel(r), channel(g), channel(b))
    }
}

extension Color {
    /// A color that resolves against the current appearance, so a `Theme` value can
    /// be read once at call sites and still follow light/dark at render time.
    static func dynamic(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
        #elseif canImport(AppKit)
        return Color(NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(isDark ? dark : light)
        })
        #else
        return dark
        #endif
    }
}

/// Semantic palette. The dark values are the original ones; the light values are
/// their counterparts, keeping the same ordering (background behind surface behind
/// surfaceRaised) so elevation reads the same way in both appearances.
enum Theme {
//    static let accent = Color.dynamic(light: Color(hex: 0xA97B10), dark: Color(hex: 0xDEAA22))
    static let accent = Color.dynamic(light: Color(hex: 0x000000), dark: Color(hex: 0xFFFFFF))
    static let background = Color.dynamic(light: Color(hex: 0xE8E8E3), dark: Color(hex: 0x0C0C0E))
    static let surface = Color.dynamic(light: Color(hex: 0xFBFBF9), dark: Color(hex: 0x161618))
    static let surfaceRaised = Color.dynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1E1E21))
    static let stroke = Color.dynamic(light: Color.black.opacity(0.10), dark: Color.white.opacity(0.08))
    static let textPrimary = Color.dynamic(light: Color(hex: 0x1A1A1C), dark: Color(hex: 0xF5F5F7))
    static let textSecondary = Color.dynamic(light: Color(hex: 0x66666C), dark: Color(hex: 0x9A9AA0))
    static let textTertiary = Color.dynamic(light: Color(hex: 0x96969C), dark: Color(hex: 0x5E5E63))
    static let danger = Color.dynamic(light: Color(hex: 0xE5484D), dark: Color(hex: 0xE5484D))
}
