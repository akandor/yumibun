//
//  MoodistApp.swift
//  Moodist
//
//  Created by Armin on 16.07.26.
//

import SwiftUI

@main
struct MoodistApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
            #if os(macOS)
                // Keep the window from being dragged down to a size where the sidebar,
                // grid and player bar collapse into each other.
                .frame(minWidth: 840, minHeight: 560)
            #endif
        }
        #if os(macOS)
        // A roomy default so the sidebar, sound grid and player all breathe; the
        // window stays freely resizable from there.
        .defaultSize(width: 1100, height: 780)
        .windowResizability(.contentMinSize)
        #endif
    }
}

/// Holds the splash over the app until it finishes, then fades it away.
///
/// Also the single place the appearance is applied: setting it here overrides the
/// whole window, so sheets and the full-screen player inherit it too.
private struct RootView: View {
    @StateObject private var appearance = AppearanceSettings()
    @StateObject private var language = LanguageSettings()
    @State private var showSplash = true
    /// Persisted so the introduction only appears on the very first launch.
    @AppStorage("moodist.hasCompletedIntro") private var hasCompletedIntro = false

    var body: some View {
        ZStack {
            ContentView()

            // Sits above the app but below the splash, so first launch reads:
            // splash → introduction → app.
            if !hasCompletedIntro {
                onboarding
                    .transition(.opacity)
                    .zIndex(1)
            }

            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.45)) { showSplash = false }
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .environmentObject(appearance)
        .environmentObject(language)
        // Applied at the root so every screen, sheet and the full player follow the
        // in-app language choice; `Text(LocalizedStringKey)` reads this locale.
        .environment(\.locale, language.resolvedLocale)
        .appearance(appearance.mode)
    }

    /// The first-launch introduction. On iPhone it fills the screen; on iPad and macOS
    /// — where a full-screen takeover feels heavy — it floats as a centered card over a
    /// dimmed backdrop instead.
    @ViewBuilder
    private var onboarding: some View {
        let view = OnboardingView {
            withAnimation(.easeInOut(duration: 0.45)) { hasCompletedIntro = true }
        }

        if isPhone {
            view
        } else {
            ZStack {
                Rectangle()
                    .fill(.black.opacity(0.45))
                    .ignoresSafeArea()

                view
                    .frame(maxWidth: 460, maxHeight: 660)
                    .background(Theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Theme.stroke, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 30, y: 12)
                    .padding(40)
            }
        }
    }
}
