import GalleryCore
import SwiftUI

struct PhotoCell: View {
    let route: FullScreenRoute
    let caption: String
    let zoomNamespace: Namespace.ID
    let onOpen: (FullScreenRoute) -> Void

    @State private var model: PhotoImageModel

    init(
        photo: Photo,
        images: PhotoImages,
        size: ImageSize,
        streamID: String,
        zoomNamespace: Namespace.ID,
        onOpen: @escaping (FullScreenRoute) -> Void
    ) {
        route = FullScreenRoute(photo: photo, gridSize: size, sourceID: "\(streamID)-\(photo.id)")
        caption = GalleryUI.caption(for: photo)
        self.zoomNamespace = zoomNamespace
        self.onOpen = onOpen
        _model = State(initialValue: PhotoImageModel(photo: photo, images: images, size: size))
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .aspectRatio(1, contentMode: .fit)
            .accessibilityElement()
            .accessibilityLabel(caption)
            .accessibilityValue(model.isLoaded ? Text(verbatim: "") : Text("Loading", bundle: .module))
            .accessibilityAddTraits(.isImage)
            .accessibilityIdentifier("photo-cell")
            .accessibilityHint(Text("Opens the photo full screen", bundle: .module))
            .accessibilityAction(.default) {
                onOpen(route)
            }
            .accessibilityRemoveTraits(.isButton)
            .overlay {
                images
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .bottom) {
                captionLabel
                    .accessibilityHidden(true)
            }
            .clipped()
            .task(id: route.gridSize) {
                guard route.gridSize.pixels > 0 else { return }
                await model.load(size: route.gridSize)
            }
            .onTapGesture {
                onOpen(route)
            }
            .zoomTransitionSource(id: route.sourceID, in: zoomNamespace)
    }

    private var images: some View {
        ZStack {
            if !model.wasCachedOnAppear, let preview = model.preview {
                Image(decorative: preview, scale: 1)
                    .filling()
            }
            if let image = model.image {
                Image(decorative: image, scale: route.gridSize.scale)
                    .filling()
                    .transition(.opacity)
            }
        }
        .animation(fadeAnimation, value: model.isLoaded)
    }

    private var captionLabel: some View {
        Text(verbatim: caption)
            .font(.caption)
            .lineLimit(1)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 16)
            .padding(.bottom, 6)
            .background(LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .top, endPoint: .bottom))
    }

    private var fadeAnimation: Animation? {
        model.wasCachedOnAppear || reduceMotion ? nil : .easeOut(duration: 0.25)
    }
}
