import GalleryCore
import SwiftUI

struct PhotoGrid: View {
    let photos: [Photo]
    let footer: StreamState.Footer
    let images: PhotoImages
    let streamID: String
    let zoomNamespace: Namespace.ID
    let onPhotoAppear: (Photo) -> Void
    let onOpen: (FullScreenRoute) -> Void
    let onRetry: () -> Void

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        ScrollView {
            SquareGrid { cellSide in
                let size = ImageSize(points: cellSide, scale: displayScale)
                ForEach(photos, id: \.id) { photo in
                    PhotoCell(
                        photo: photo,
                        images: images,
                        size: size,
                        streamID: streamID,
                        zoomNamespace: zoomNamespace,
                        onOpen: onOpen
                    )
                    .onAppear {
                        onPhotoAppear(photo)
                        prefetch(after: photo, size: size)
                    }
                }
            }
            FooterView(footer: footer, onRetry: onRetry)
        }
        .accessibilityIdentifier("photo-grid")
    }

    private func prefetch(after photo: Photo, size: ImageSize) {
        guard size.pixels > 0 else { return }
        let window = prefetchWindow(after: photo, in: photos, distance: images.prefetchDistance)
        images.prefetch(Array(window), size)
    }
}

struct SquareGrid<Content: View>: View {
    @ViewBuilder let content: (_ cellSide: CGFloat) -> Content

    @State private var width: CGFloat = 0

    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private var columnCount: Int { horizontalSizeClass == .regular ? 3 : 2 }
    #else
        private let columnCount = 3
    #endif

    private var cellSide: CGFloat {
        let spacing = gridSpacing * CGFloat(columnCount - 1)
        return max(0, ((width - spacing) / CGFloat(columnCount)).rounded(.down))
    }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: columnCount),
            spacing: gridSpacing
        ) {
            content(cellSide)
        }
        .onGeometryChange(for: CGFloat.self) {
            $0.size.width
        } action: {
            width = $0
        }
    }
}

private let gridSpacing: CGFloat = 2

struct PhotoCell: View {
    let route: FullScreenRoute
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
        self.zoomNamespace = zoomNamespace
        self.onOpen = onOpen
        _model = State(initialValue: PhotoImageModel(photo: photo, images: images, size: size))
    }

    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    if !model.wasCachedOnAppear, let preview = model.preview {
                        Image(decorative: preview, scale: 1)
                            .resizable()
                            .scaledToFill()
                    }
                    if let image = model.image {
                        Image(decorative: image, scale: route.gridSize.scale)
                            .resizable()
                            .scaledToFill()
                            .transition(.opacity)
                    }
                }
                .animation(model.wasCachedOnAppear ? nil : .easeOut(duration: 0.25), value: model.isLoaded)
            }
            .clipped()
            .task(id: route.gridSize) {
                guard route.gridSize.pixels > 0 else { return }
                await model.load(size: route.gridSize)
            }
            .accessibilityElement()
            .accessibilityLabel(caption(for: route.photo))
            .accessibilityValue(model.isLoaded ? Text(verbatim: "") : Text("Loading", bundle: .module))
            .accessibilityAddTraits(.isImage)
            .accessibilityIdentifier("photo-cell")
            .accessibilityHint(Text("Opens the photo full screen", bundle: .module))
            .accessibilityAction(.default) {
                onOpen(route)
            }
            .onTapGesture {
                onOpen(route)
            }
            .accessibilityRemoveTraits(.isButton)
            .zoomTransitionSource(id: route.sourceID, in: zoomNamespace)
    }
}

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
            VStack(spacing: 8) {
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
