import SwiftUI

struct OfflineBanner: View {
    let reason: LoadError

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: reason.systemImage)
            text
        }
        .font(.subheadline)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: Capsule())
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("offline-banner")
    }

    private var text: Text {
        reason == .offline
            ? Text("You're offline · Showing saved photos", bundle: .module)
            : Text("Showing saved photos", bundle: .module)
    }
}
