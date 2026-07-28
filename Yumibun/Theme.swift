//
//  Theme.swift
//  Yumibun
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
    /// The accent tint, chosen from `AccentPalette` in Settings and persisted. It's a
    /// computed property (not a `let`) so every `Theme.accent` call site picks up the
    /// current choice the next time its view body runs.
    static var accent: Color { accentPalette.color }

    /// The currently selected palette. Backed by `UserDefaults` so it survives launches
    /// and can be read statically from anywhere; `AppearanceSettings` writes through it
    /// and publishes the change so SwiftUI re-renders live.
    static var accentPalette: AccentPalette {
        get { AccentPalette(rawValue: UserDefaults.standard.string(forKey: accentKey) ?? "") ?? .peach }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: accentKey) }
    }

    static let accentKey = "yumibun.accent"

    static let background = Color.dynamic(light: Color(hex: 0xE8E8E3), dark: Color(hex: 0x0C0C0E))
    static let surface = Color.dynamic(light: Color(hex: 0xFBFBF9), dark: Color(hex: 0x161618))
    static let surfaceRaised = Color.dynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1E1E21))
    static let stroke = Color.dynamic(light: Color.black.opacity(0.10), dark: Color.white.opacity(0.08))
    static let textPrimary = Color.dynamic(light: Color(hex: 0x1A1A1C), dark: Color(hex: 0xF5F5F7))
    static let textSecondary = Color.dynamic(light: Color(hex: 0x66666C), dark: Color(hex: 0x9A9AA0))
    static let textTertiary = Color.dynamic(light: Color(hex: 0x96969C), dark: Color(hex: 0x5E5E63))
    static let danger = Color.dynamic(light: Color(hex: 0xE5484D), dark: Color(hex: 0xE5484D))
}

/// The accent tints the app can be themed with. Each carries a light/dark pair that
/// keeps the same character in both appearances. `pure` is the monochrome option —
/// black on light, white on dark — and is what makes the logo mark fall back to
/// `textSecondary` rather than an accent hue.
enum AccentPalette: String, CaseIterable, Identifiable {
    case pure
    case lavender
    case sage
    case peach
    case cyan

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .pure: "Pure"
        case .lavender: "Soft Lavender"
        case .sage: "Sage Green"
        case .peach: "Warm Peach"
        case .cyan: "Misty Cyan"
        }
    }

    var color: Color {
        switch self {
        case .pure: .dynamic(light: Color(hex: 0x000000), dark: Color(hex: 0xFFFFFF))
        case .lavender: .dynamic(light: Color(hex: 0x7357D8), dark: Color(hex: 0xB8A7FF))
        case .sage: .dynamic(light: Color(hex: 0x4F8B69), dark: Color(hex: 0x8EC9A8))
        case .peach: .dynamic(light: Color(hex: 0xD67B45), dark: Color(hex: 0xF0B78A))
        case .cyan: .dynamic(light: Color(hex: 0x2E8EA5), dark: Color(hex: 0x7FD6E5))
        }
    }

    /// The accent as it should read over a dark surface (e.g. the photo hero), where the
    /// light-mode variant of `.pure` — black — would vanish. Always the lighter of the
    /// pair, so it stays legible regardless of the app's appearance.
    var colorOnDark: Color {
        switch self {
        case .pure: Color(hex: 0xFFFFFF)
        case .lavender: Color(hex: 0xB8A7FF)
        case .sage: Color(hex: 0x8EC9A8)
        case .peach: Color(hex: 0xF0B78A)
        case .cyan: Color(hex: 0x7FD6E5)
        }
    }
}
