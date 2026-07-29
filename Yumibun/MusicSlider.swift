//
//  MusicSlider.swift
//  Yumibun
//
//  A thin, thumbless volume slider modelled on the iOS Music app: at rest it's
//  a slim capsule with no handle; the moment you press it the bar swells taller
//  and the fill tracks your finger, then it settles back when you let go.
//

import SwiftUI

struct MusicSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    var tint: Color = Theme.accent

    /// Bar thickness at rest and while actively being dragged.
    var restHeight: CGFloat = 6
    var activeHeight: CGFloat = 11
    /// Comfortable touch target the thin bar lives inside of.
    var touchHeight: CGFloat = 28

    @Environment(\.isEnabled) private var isEnabled
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let barHeight = isDragging ? activeHeight : restHeight
            let fillWidth = min(width, max(barHeight, width * fraction))

            ZStack(alignment: .leading) {
                Capsule().fill(Theme.textPrimary.opacity(0.14))
                Capsule().fill(tint).frame(width: fillWidth)
            }
            .frame(height: barHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        if !isDragging {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                                isDragging = true
                            }
                        }
                        setValue(fromX: g.location.x, width: width)
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                            isDragging = false
                        }
                    }
            )
        }
        .frame(height: touchHeight)
        .accessibilityElement()
        .accessibilityValue(Text("\(Int((fraction * 100).rounded())) percent"))
        .accessibilityAdjustableAction { direction in
            let step = (range.upperBound - range.lowerBound) * 0.05
            switch direction {
            case .increment: value = min(range.upperBound, value + step)
            case .decrement: value = max(range.lowerBound, value - step)
            @unknown default: break
            }
        }
    }

    private var fraction: CGFloat {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        return CGFloat((clamped - range.lowerBound) / span)
    }

    private func setValue(fromX x: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        let f = min(max(0, x / width), 1)
        value = range.lowerBound + Double(f) * (range.upperBound - range.lowerBound)
    }
}
