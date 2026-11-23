import SwiftUI

extension View {
    func glassCircle() -> some View {
        modifier(GlassCircle())
    }
}

private struct GlassCircle: ViewModifier {
    func body(content: Content) -> some View {
        let sized =
            content
            .frame(width: Design.Size.hitTarget, height: Design.Size.hitTarget)
            .contentShape(.circle)
        if #available(iOS 26, macOS 26, *) {
            sized.glassEffect(.regular.interactive(), in: .circle)
        } else {
            sized.background(.ultraThinMaterial, in: .circle)
        }
    }
}
