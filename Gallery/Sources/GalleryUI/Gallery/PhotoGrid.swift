import GalleryCore
import SwiftUI

struct PhotoGrid: View {
    let photos: [Photo]
    let footer: StreamState.Footer
    let images: PhotoImages
    let streamID: String
    let zoomNamespace: Namespace.ID
    let focusedPhotoID: String?
    var hero: Hero?
    let onPhotoAppear: (Photo) -> Void
    let onOpen: (FullScreenRoute) -> Void
    let onRetry: () -> Void

    struct Hero {
        let photo: Photo
        let appName: String
    }

    @Environment(\.displayScale) private var displayScale
    @State private var container = CGSize.zero

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
                Section {
                    cells(size: size)
                } header: {
                    if let hero {
                        heroHeader(hero, gridSize: size)
                    }
                }
            }
            FooterView(footer: footer, onRetry: onRetry)
        }
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: {
            container = $0
        }
        .accessibilityIdentifier("photo-grid")
    }

    private var gridPhotos: ArraySlice<Photo> {
        hero == nil ? photos[...] : photos.dropFirst()
    }

    private func heroHeader(_ hero: Hero, gridSize: ImageSize) -> some View {
        let height = Design.Hero.height(for: container)
        return HeroHeader(
            photo: hero.photo,
            images: images,
            gridSize: gridSize,
            imageSize: ImageSize(points: max(container.width, height), scale: displayScale),
            height: height,
            streamID: streamID,
            appName: hero.appName,
            zoomNamespace: zoomNamespace,
            onOpen: onOpen
        )
        .id(hero.photo.id)
        .onAppear { onPhotoAppear(hero.photo) }
    }

    @ViewBuilder
    private func cells(size: ImageSize) -> some View {
        ForEach(gridPhotos, id: \.id) { photo in
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

    private func prefetch(after photo: Photo, size: ImageSize) {
        guard size.pixels > 0 else { return }
        let window = prefetchWindow(after: photo, in: photos, distance: images.prefetchDistance)
        images.prefetch(Array(window), size)
    }
}
