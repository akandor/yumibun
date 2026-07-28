import SwiftUI

/// The Yumibun mark, turning slowly and continuously.
///
/// The asset is a template image, so it takes `tint` rather than the white baked
/// into the SVG. The spin lives here so every place the mark appears turns at the
/// same rate; callers can still layer their own transforms on top.
struct LogoMark: View {
    var size: CGFloat = 112
    /// An explicit tint override. When `nil` the mark follows the accent palette:
    /// `Pure` renders monochrome via `textSecondary`, every other palette uses its accent.
    var tint: Color? = nil
    /// Seconds per revolution.
    var revolution: Double = 24

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var spinning = false

    /// `Pure` is the monochrome palette, so the mark drops to `textSecondary` there
    /// instead of a colored accent; every other palette tints it with the accent.
    private var resolvedTint: Color {
        tint ?? (Theme.accentPalette == .pure ? Theme.textSecondary : Theme.accent)
    }

    var body: some View {
        Image("logo")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(resolvedTint)
            .rotationEffect(.degrees(spinning ? 360 : 0))
            .onAppear {
                // A perpetual rotation is the kind of motion Reduce Motion exists
                // to suppress, so it stays still there.
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: revolution).repeatForever(autoreverses: false)) {
                    spinning = true
                }
            }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        LogoMark()
    }
}
