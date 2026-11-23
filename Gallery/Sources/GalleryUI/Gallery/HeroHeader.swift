import GalleryCore
import SwiftUI

struct HeroHeader: View {
    let route: FullScreenRoute
    let caption: String
    let imageSize: ImageSize
    let height: CGFloat
    let appName: String
    let zoomNamespace: Namespace.ID
    let onOpen: (FullScreenRoute) -> Void

    @State private var model: PhotoImageModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        photo: Photo,
        images: PhotoImages,
        gridSize: ImageSize,
        imageSize: ImageSize,
        height: CGFloat,
        streamID: String,
        appName: String,
        zoomNamespace: Namespace.ID,
        onOpen: @escaping (FullScreenRoute) -> Void
    ) {
        route = FullScreenRoute(photo: photo, gridSize: gridSize, streamID: streamID)
        caption = GalleryUI.caption(for: photo)
        self.imageSize = imageSize
        self.height = height
        self.appName = appName
        self.zoomNamespace = zoomNamespace
        self.onOpen = onOpen
        _model = State(initialValue: PhotoImageModel(photo: photo, images: images, size: imageSize))
    }

    var body: some View {
        Color.clear
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) { stretchingImage }
            .overlay(alignment: .bottom) { captionBlock }
            .contentShape(Rectangle())
            .onTapGesture { onOpen(route) }
            .zoomTransitionSource(id: route.sourceID, in: zoomNamespace)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(caption)
            .accessibilityAddTraits(.isImage)
            .accessibilityHint(Text("Opens the photo full screen", bundle: .module))
            .accessibilityAction(.default) { onOpen(route) }
            .accessibilityIdentifier("hero")
            .task(id: imageSize) {
                guard imageSize.pixels > 0 else { return }
                await model.load(size: imageSize)
            }
    }

    private var stretchingImage: some View {
        images
            .frame(height: height)
            .visualEffect { [height] content, proxy in
                let stretch = HeroStretch(minY: proxy.frame(in: .scrollView).minY, baseHeight: height)
                return
                    content
                    .scaleEffect(stretch.height / max(height, 1), anchor: .top)
                    .offset(y: stretch.offset)
            }
            .mask(alignment: .bottom) {
                Rectangle().frame(height: height * 4)
            }
            .accessibilityHidden(true)
    }

    private var images: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            if !model.wasCachedOnAppear, let preview = model.preview {
                Image(decorative: preview, scale: 1)
                    .filling()
            }
            if let image = model.image {
                Image(decorative: image, scale: imageSize.scale)
                    .filling()
                    .transition(.opacity)
            }
        }
        .animation(
            model.wasCachedOnAppear ? nil : Design.Motion.imageFade(reduceMotion: reduceMotion),
            value: model.isLoaded
        )
    }

    private var captionBlock: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            Text(verbatim: caption)
                .font(.title2.bold())
                .lineLimit(2)
            PhotoCreditView(photographer: route.photo.photographer, appName: appName)
                .tint(.white)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Design.Spacing.medium)
        .padding(.top, Design.Spacing.medium * 3)
        .padding(.bottom, Design.Spacing.medium)
        .background(Scrim())
    }
}
