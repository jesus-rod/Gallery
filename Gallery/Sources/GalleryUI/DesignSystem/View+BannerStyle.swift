import SwiftUI

extension View {
    func bannerStyle() -> some View {
        font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Design.Spacing.medium)
            .padding(.vertical, Design.Spacing.small)
            .background(
                .thinMaterial,
                in: RoundedRectangle(cornerRadius: Design.Size.bannerCornerRadius, style: .continuous)
            )
            .padding(.horizontal, Design.Spacing.medium)
            .padding(.top, Design.Spacing.small)
    }
}
