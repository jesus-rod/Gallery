import SwiftUI

struct RefreshErrorBanner: View {
    let error: LoadError
    let onDismiss: () -> Void

    var body: some View {
        Text(error.title)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .task {
                try? await Task.sleep(for: .seconds(3))
                onDismiss()
            }
            .accessibilityIdentifier("refresh-error")
    }
}
