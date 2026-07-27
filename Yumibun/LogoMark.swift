import SwiftUI

/// The Yumibun mark, turning slowly and continuously.
///
/// The asset is a template image, so it takes `tint` rather than the white baked
/// into the SVG. The spin lives here so every place the mark appears turns at the
/// same rate; callers can still layer their own transforms on top.
struct LogoMark: View {
    var size: CGFloat = 112
    var tint: Color = Theme.textSecondary
    /// Seconds per revolution.
    var revolution: Double = 24

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var spinning = false

    var body: some View {
        Image("logo")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(tint)
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
