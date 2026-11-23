import SwiftUI

struct LoadErrorView: View {
    let error: LoadError
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(error.title, systemImage: error.systemImage)
        } description: {
            Text(error.message)
        } actions: {
            Button(action: onRetry) {
                Text("Retry", bundle: .module)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("retry-button")
        }
        .accessibilityIdentifier("feed-error")
    }
}
