import CoreGraphics
import SwiftUI

struct AmbientBackdrop: View {
    let preview: CGImage?
    let opacity: Double

    static func opacity(isChromeVisible: Bool, dismissProgress: Double, reduceTransparency: Bool) -> Double {
        guard isChromeVisible, !reduceTransparency else { return 0 }
        return 1 - dismissProgress
    }

    var body: some View {
        if let preview {
            Image(decorative: preview, scale: 1)
                .interpolation(.high)
                .filling()
                .overlay(Color.black.opacity(Design.Ambient.dim))
                .opacity(opacity)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        }
    }
}
