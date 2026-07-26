import SwiftUI

/// Brand moment on launch: the logo settles in, the title rises under it, and the
/// whole thing hands over to the app.
///
/// The logo asset is a template image, so it takes its colour from the tint here
/// rather than the white baked into the SVG.
struct SplashView: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var logoIn = false
    @State private var titleIn = false
    @State private var breathing = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                // LogoMark owns the perpetual spin; these stack the entrance on top.
                LogoMark(size: 112)
                    .opacity(logoIn ? 1 : 0)
                    .rotationEffect(.degrees(logoIn ? 0 : -60))
                    // Two separate scales so the entrance spring and the idle
                    // breathing don't fight over one value.
                    .scaleEffect(logoIn ? 1 : 0.7)
                    .scaleEffect(breathing ? 1.04 : 1)

                Text("Moodist")
                    .font(.system(size: 36, design: .serif))
                    .foregroundStyle(Theme.textPrimary)
                    .opacity(titleIn ? 1 : 0)
                    .offset(y: titleIn ? 0 : 12)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Moodist")
        .task { await run() }
    }

    private func run() async {
        guard !reduceMotion else {
            withAnimation(.easeOut(duration: 0.35)) {
                logoIn = true
                titleIn = true
            }
            try? await Task.sleep(for: .seconds(1.0))
            onFinish()
            return
        }

        withAnimation(.spring(response: 0.85, dampingFraction: 0.62)) { logoIn = true }

        try? await Task.sleep(for: .seconds(0.32))
        withAnimation(.easeOut(duration: 0.5)) { titleIn = true }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { breathing = true }

        try? await Task.sleep(for: .seconds(1.45))
        onFinish()
    }
}

#Preview {
    SplashView {}
}
