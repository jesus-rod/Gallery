import CoreGraphics
import GalleryCore
import Observation

@MainActor
@Observable
final class FullScreenImageModel {
    enum State: Equatable {
        case preview(CGImage?)
        case gridImage(CGImage)
        case fullImage(CGImage)
    }

    private enum Loaded: Sendable {
        case gridImage(CGImage)
        case fullImage(CGImage)
    }

    private(set) var state: State
    private let photo: Photo
    private let images: PhotoImages
    private let gridSize: ImageSize

    init(photo: Photo, images: PhotoImages, gridSize: ImageSize) {
        self.photo = photo
        self.images = images
        self.gridSize = gridSize
        self.state = .preview(images.preview(photo))
    }

    var isFullImageShown: Bool {
        if case .fullImage = state { return true }
        return false
    }

    func load(fitting size: FittingSize) async {
        let needsGridImage = !isFullImageShown
        await withTaskGroup(of: Loaded?.self) { group in
            if needsGridImage {
                group.addTask { [images, photo, gridSize] in
                    (try? await images.image(photo, gridSize)).map(Loaded.gridImage)
                }
            }
            group.addTask { [images, photo] in
                (try? await images.fullScreenImage(photo, size)).map(Loaded.fullImage)
            }
            for await loaded in group {
                apply(loaded)
            }
        }
    }

    private func apply(_ loaded: Loaded?) {
        switch loaded {
        case .gridImage(let image)?:
            if case .preview = state { state = .gridImage(image) }
        case .fullImage(let image)?:
            state = .fullImage(image)
        case nil:
            break
        }
    }
}
