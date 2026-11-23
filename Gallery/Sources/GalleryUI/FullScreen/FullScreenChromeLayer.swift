import GalleryCore
import SwiftUI

struct FullScreenChromeLayer: View {
    let caption: String
    let photographer: Photo.Photographer
    let shareURL: URL
    let appName: String
    let isVisible: Bool
    @Binding var isInfoPresented: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 0)
            bottomBar
        }
        .padding(.horizontal, Design.Spacing.medium)
        .padding(.vertical, Design.Spacing.small)
        .background(alignment: .top) { titleScrim }
        .foregroundStyle(.white)
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
        .accessibilityElement(children: .contain)
        .accessibilityHidden(!isVisible)
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: Design.Spacing.small) {
            Button(action: close) {
                Image(systemName: "chevron.backward")
                    .font(.title3.weight(.semibold))
                    .glassCircle()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Back", bundle: .module))
            .accessibilityIdentifier("full-screen-close")
            title
                .frame(maxWidth: .infinity)
            Color.clear
                .frame(width: Design.Size.hitTarget, height: Design.Size.hitTarget)
                .accessibilityHidden(true)
        }
    }

    private var title: some View {
        VStack(spacing: 2) {
            Text(verbatim: caption)
                .font(.headline)
                .lineLimit(1)
            Link(destination: UnsplashAttribution.referralURL(photographer.profileURL, appName: appName)) {
                Text("Photo by \(photographer.name)", bundle: .module)
                    .font(.footnote)
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(Design.Opacity.secondaryText))
            .accessibilityIdentifier("photo-credit")
        }
        .multilineTextAlignment(.center)
        .frame(minHeight: Design.Size.hitTarget)
    }

    private var bottomBar: some View {
        HStack {
            ShareLink(item: shareURL, preview: SharePreview(caption)) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3.weight(.semibold))
                    .glassCircle()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Share", bundle: .module))
            Spacer()
            Button(action: showInfo) {
                Image(systemName: "info.circle")
                    .font(.title3.weight(.semibold))
                    .glassCircle()
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Info", bundle: .module))
        }
    }

    private var titleScrim: some View {
        LinearGradient(
            colors: [.black.opacity(Design.Opacity.titleScrim), .clear], startPoint: .top, endPoint: .bottom
        )
        .frame(height: 160)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func close() {
        dismiss()
    }

    private func showInfo() {
        isInfoPresented = true
    }
}
