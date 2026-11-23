import GalleryCore
import SwiftUI

struct FullScreenCaptionLayer: View {
    let caption: String
    let photographer: Photo.Photographer
    let appName: String
    let maxHeight: CGFloat
    let isVisible: Bool

    var body: some View {
        ViewThatFits(in: .vertical) {
            captionBlock
            ScrollView { captionBlock }
        }
        .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .leading)
        .padding()
        .background(LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
        .frame(maxHeight: .infinity, alignment: .bottom)
        .safeAreaPadding()
        .foregroundStyle(.white)
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
        .accessibilityHidden(!isVisible)
    }

    private var captionBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: caption)
                .font(.headline)
                .lineLimit(3)
            PhotoCreditView(photographer: photographer, appName: appName)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
