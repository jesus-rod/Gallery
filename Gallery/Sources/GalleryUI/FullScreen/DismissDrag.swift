import SwiftUI

@MainActor
@Observable
final class DismissDrag {
    var translation = CGSize.zero

    var progress: Double {
        ZoomTransform.dismissProgress(for: translation)
    }
}

struct DismissOffset: ViewModifier {
    let drag: DismissDrag

    func body(content: Content) -> some View {
        content.offset(y: drag.translation.height)
    }
}

struct DismissFadingBlack: View {
    let drag: DismissDrag

    var body: some View {
        Color.black.opacity(1 - drag.progress)
    }
}

struct DismissFadingAmbient: View {
    let preview: CGImage?
    let drag: DismissDrag
    let isChromeVisible: Bool
    let reduceTransparency: Bool

    var body: some View {
        AmbientBackdrop(
            preview: preview,
            opacity: AmbientBackdrop.opacity(
                isChromeVisible: isChromeVisible,
                dismissProgress: drag.progress,
                reduceTransparency: reduceTransparency
            )
        )
    }
}
