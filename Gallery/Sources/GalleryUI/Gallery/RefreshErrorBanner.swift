import SwiftUI

struct RefreshErrorBanner: View {
    let error: LoadError
    let onDismiss: () -> Void

    var body: some View {
        Text(error.title)
            .bannerStyle()
            .transition(.move(edge: .top).combined(with: .opacity))
            .task {
                try? await Task.sleep(for: .seconds(3))
                onDismiss()
            }
            .accessibilityIdentifier("refresh-error")
    }
}
