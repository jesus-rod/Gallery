import SwiftUI

struct OfflineBanner: View {
    let reason: LoadError

    var body: some View {
        HStack(spacing: Design.Spacing.small) {
            Image(systemName: reason.systemImage)
            text
        }
        .bannerStyle()
        .padding(.bottom, Design.Spacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("offline-banner")
    }

    private var text: Text {
        reason == .offline
            ? Text("You're offline · Showing saved photos", bundle: .module)
            : Text("Showing saved photos", bundle: .module)
    }
}
