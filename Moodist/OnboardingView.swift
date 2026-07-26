//
//  OnboardingView.swift
//  Moodist
//
//  A four-page introduction shown once on first launch. Each page pairs an icon, a
//  title and a blurb; a chip at the top tracks progress (e.g. "01 / 04").
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = 0

    private let pages: [IntroPage] = [
        IntroPage(
            icon: "waveform",
            title: "Free Ambient Sounds",
            text: "Craving a calming escape from the daily grind? Do you need the perfect soundscape to boost your focus or lull you into peaceful sleep? Look no further than Moodist, your free and open-source ambient sound generator! Ditch the subscriptions and registrations — with Moodist, you unlock a world of soothing and immersive audio experiences, entirely for free."
        ),
        IntroPage(
            icon: "music.note.list",
            title: "Carefully Curated Sounds",
            text: "Dive into an expansive library of 84 carefully curated sounds. Nature lovers will find solace in the gentle murmur of streams, the rhythmic crash of waves, or the crackling warmth of a campfire. Cityscapes come alive with the soft hum of cafes, the rhythmic clatter of trains, or the calming white noise of traffic. And for deeper focus or relaxation, Moodist offers binaural beats and color noise."
        ),
        IntroPage(
            icon: "slider.horizontal.3",
            title: "Create Your Soundscape",
            text: "The beauty of Moodist lies in its simplicity and customization. No complex menus or confusing options — just choose your desired sounds, adjust the volume balance, and hit play. Want to blend the gentle chirping of birds with the soothing sound of rain? No problem! Layer as many sounds as you like to create your personalized soundscape oasis."
        ),
        IntroPage(
            icon: "sparkles",
            title: "Sounds for Every Moment",
            text: "Whether you're looking to unwind after a long day, enhance your focus during work, or lull yourself into a peaceful sleep, Moodist has the perfect soundscape waiting for you. The best part? It's completely free and open-source, so you can enjoy its benefits without any strings attached. Start your new haven of tranquility and focus!"
        ),
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                pageChip
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                pager

                bottomControls
            }
        }
    }

    /// The swipeable page carousel. macOS has no `.page` tab style, so there the
    /// current page is shown directly and the Back/Continue buttons drive it.
    @ViewBuilder
    private var pager: some View {
        #if os(iOS)
        TabView(selection: $page) {
            ForEach(pages.indices, id: \.self) { index in
                IntroPageView(page: pages[index])
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.snappy(duration: 0.3), value: page)
        #else
        IntroPageView(page: pages[page])
            .id(page)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .animation(.snappy(duration: 0.3), value: page)
        #endif
    }

    /// The "01 / 04" progress chip, animating as the page changes.
    private var pageChip: some View {
        Text(String(format: "%02d / %02d", page + 1, pages.count))
            .font(.system(size: 13, weight: .semibold))
            .monospacedDigit()
            .contentTransition(.numericText())
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(Theme.surface))
            .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
            .animation(.snappy(duration: 0.3), value: page)
    }

    private var bottomControls: some View {
        VStack(spacing: 22) {
            // Progress dots.
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Theme.accent : Theme.stroke)
                        .frame(width: index == page ? 20 : 7, height: 7)
                        .animation(.snappy(duration: 0.3), value: page)
                }
            }

            Button {
                if isLastPage {
                    onFinish()
                } else {
                    withAnimation(.snappy(duration: 0.3)) { page += 1 }
                }
            } label: {
                Text(isLastPage ? "Use Moodist" : "Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Theme.accent))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 44)
    }
}

/// One intro page. The body scrolls so the longer blurbs never clip on small screens.
private struct IntroPageView: View {
    let page: IntroPage

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 26) {
                ZStack {
                    Circle().fill(Theme.surface)
                    Circle().strokeBorder(Theme.stroke, lineWidth: 1)
                    Image(systemName: page.icon)
                        .font(.system(size: 46, weight: .medium))
                        .foregroundStyle(Theme.accent)
                }
                .frame(width: 124, height: 124)

                VStack(spacing: 14) {
                    Text(page.title)
                        .font(.system(size: 28, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(page.text)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }
}

struct IntroPage {
    let icon: String
    // LocalizedStringKey (not String) so the literals below are extracted into the
    // string catalog and localized when rendered by `Text`.
    let title: LocalizedStringKey
    let text: LocalizedStringKey
}

#Preview {
    OnboardingView {}
}
