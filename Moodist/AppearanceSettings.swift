import Combine
import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Which appearance the app renders in. `.system` defers to iOS, which is the
/// default; the other two pin it regardless of the device setting.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: "iphone"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

#if canImport(UIKit)
    /// `.unspecified` hands the choice back to the device setting.
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
#endif
}

@MainActor
final class AppearanceSettings: ObservableObject {
    @Published var mode: AppearanceMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.modeKey) }
    }

    private static let modeKey = "moodist.appearanceMode"

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.modeKey)
        mode = stored.flatMap(AppearanceMode.init(rawValue:)) ?? .system
    }
}

extension View {
    /// Applies the mode to the window itself rather than via `preferredColorScheme`.
    ///
    /// `preferredColorScheme(nil)` does not undo a scheme it previously forced, so
    /// going Light → System would leave the app stuck in light until the next
    /// launch. Setting the window's style to `.unspecified` is what actually hands
    /// the choice back to the device. Overriding the window also covers the sheets
    /// and the full-screen player, which are presented in this same window.
    func appearance(_ mode: AppearanceMode) -> some View {
        modifier(AppearanceOverride(mode: mode))
    }
}

private struct AppearanceOverride: ViewModifier {
    let mode: AppearanceMode

    func body(content: Content) -> some View {
        content
            .onAppear { apply() }
            .onChange(of: mode) { _, _ in apply() }
    }

    private func apply() {
#if canImport(UIKit)
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = mode.interfaceStyle
            }
        }
#elseif canImport(AppKit)
        if let app = NSApp {
            switch mode {
            case .system:
                app.appearance = nil
            case .light:
                app.appearance = NSAppearance(named: .aqua)
            case .dark:
                app.appearance = NSAppearance(named: .darkAqua)
            }
        }
#endif
    }
}
