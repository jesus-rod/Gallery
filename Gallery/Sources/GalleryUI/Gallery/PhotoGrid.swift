import GalleryCore
import SwiftUI

struct PhotoGrid: View {
    let photos: [Photo]
    let footer: StreamState.Footer
    let images: PhotoImages
    let streamID: String
    let zoomNamespace: Namespace.ID
    let focusedPhotoID: String?
    let onPhotoAppear: (Photo) -> Void
    let onOpen: (FullScreenRoute) -> Void
    let onRetry: () -> Void

    @Environment(\.displayScale) private var displayScale

    var body: some View {
        ScrollViewReader { proxy in
            grid
                .onChange(of: focusedPhotoID) { _, id in
                    guard let id, photos.contains(where: { $0.id == id }) else { return }
                    proxy.scrollTo(id, anchor: .center)
                }
        }
    }

    private var grid: some View {
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
