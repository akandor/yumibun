//
//  LanguageSettings.swift
//  Yumibun
//
//  In-app language override. iOS exposes a per-app language in the system Settings,
//  but macOS has no equally discoverable equivalent, so on macOS the app offers its
//  own picker (see SettingsView). The choice drives two things: the SwiftUI
//  environment `locale` (which localizes `Text(LocalizedStringKey)`), and a
//  bundle-aware lookup for the `NSLocalizedString` call sites in `SoundCatalog`.
//

import Combine
import Foundation
import SwiftUI

/// The languages the app ships strings for, plus "system" to defer to the OS. Each
/// non-system case is labelled in its own language (an endonym), the convention for
/// language pickers.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case german
    case spanish
    case french
    case italian
    case portugueseBrazil
    case chineseSimplified
    case japanese
    case korean

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .english: "English"
        case .german: "Deutsch"
        case .spanish: "Español"
        case .french: "Français"
        case .italian: "Italiano"
        case .portugueseBrazil: "Português (Brasil)"
        case .chineseSimplified: "简体中文"
        case .japanese: "日本語"
        case .korean: "한국어"
        }
    }

    /// The `.lproj` / locale code, or `nil` when following the system.
    var code: String? {
        switch self {
        case .system: nil
        case .english: "en"
        case .german: "de"
        case .spanish: "es"
        case .french: "fr"
        case .italian: "it"
        case .portugueseBrazil: "pt-BR"
        case .chineseSimplified: "zh-Hans"
        case .japanese: "ja"
        case .korean: "ko"
        }
    }
}

@MainActor
final class LanguageSettings: ObservableObject {
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.key) }
    }

    static let key = "yumibun.appLanguage"

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.key)
        language = stored.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    /// The locale to hand SwiftUI. A pinned language forces that locale; `system`
    /// keeps the device's own, which also lets switching *away* from a language take
    /// effect immediately.
    var resolvedLocale: Locale {
        if let code = language.code { return Locale(identifier: code) }
        return Locale.autoupdatingCurrent
    }

    /// Looks up a key in the chosen language's bundle, so the `NSLocalizedString`
    /// call sites follow the in-app choice too. Falls back to the main bundle (i.e.
    /// the system language) when no override is set or the bundle is missing.
    nonisolated static func localized(_ key: String) -> String {
        let stored = UserDefaults.standard.string(forKey: Self.key)
        if let code = stored.flatMap({ AppLanguage(rawValue: $0)?.code }),
           let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }
        return NSLocalizedString(key, comment: "")
    }
}
