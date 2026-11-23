import GalleryCore
import SwiftUI

struct FooterView: View {
    let footer: StreamState.Footer
    let onRetry: () -> Void

    var body: some View {
        switch footer {
        case .idle, .end:
            EmptyView()
        case .loading:
            ProgressView()
                .padding()
                .accessibilityIdentifier("footer-loading")
        case .failed(let error):
            VStack(spacing: Design.Spacing.small) {
                Text(error.title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(action: onRetry) {
                    Text("Retry", bundle: .module)
                }
                .accessibilityIdentifier("footer-retry")
            }
            .padding()
        }
    }
}
