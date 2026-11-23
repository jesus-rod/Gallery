import SwiftUI

struct RefreshErrorBanner: View {
    let error: LoadError
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(error.title)
            .bannerStyle()
            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            .task {
                AccessibilityNotification.Announcement(error.title).post()
                try? await Task.sleep(for: .seconds(3))
                onDismiss()
            }
            .accessibilityIdentifier("refresh-error")
    }
}
