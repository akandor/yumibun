//
//  Platform.swift
//  Moodist
//
//  Small cross-platform shims so the iOS-shaped view code compiles and behaves
//  sensibly on macOS (native AppKit, not Catalyst). Each helper collapses an
//  iOS-only API to a no-op or the AppKit equivalent, keeping the call sites free
//  of `#if os(...)` noise.
//

import SwiftUI

/// Device-idiom flags. macOS has no `UIDevice`; it lays out like the regular-width
/// (iPad-style) UI, so `isPhone` is false there and `isPad`-style layouts win.
#if os(iOS)
let isPad = UIDevice.current.userInterfaceIdiom == .pad
let isPhone = UIDevice.current.userInterfaceIdiom == .phone
#else
let isPad = true
let isPhone = false
#endif

extension View {
    /// `.navigationBarTitleDisplayMode(.inline)` on iOS; a no-op on macOS, which has
    /// no navigation bar to size.
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// The decimal keypad on iOS; a no-op on macOS, which uses the hardware keyboard.
    @ViewBuilder
    func decimalKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    /// Insets a plain `List` row from the window edges on macOS, where rows otherwise
    /// span nearly edge-to-edge. `contentMargins` doesn't affect row width for a plain
    /// list, so the padding has to live on the row itself. A no-op on iOS, which keeps
    /// its standard row insets.
    @ViewBuilder
    func rowHorizontalInsets(_ horizontal: CGFloat = 28) -> some View {
        #if os(macOS)
        self.listRowInsets(EdgeInsets(top: 6, leading: horizontal, bottom: 6, trailing: horizontal))
        #else
        self
        #endif
    }

    /// The surface for a floating control that hovers over scrolling content — the
    /// player bars and the generator pill. On iOS 26 / macOS 26 it adopts Liquid Glass
    /// so it refracts what's behind it; on earlier systems it falls back to the raised
    /// surface fill with a hairline stroke.
    @ViewBuilder
    func floatingBarSurface<S: InsettableShape>(_ shape: S) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(shape.fill(Theme.surfaceRaised))
                .overlay(shape.strokeBorder(Theme.stroke, lineWidth: 1))
        }
    }
}
