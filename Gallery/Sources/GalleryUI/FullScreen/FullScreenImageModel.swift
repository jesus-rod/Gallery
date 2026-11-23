import CoreGraphics
import GalleryCore
import Observation

@MainActor
@Observable
final class FullScreenImageModel {
    enum State: Equatable {
        case preview
        case gridImage(CGImage)
        case fullImage(CGImage)
    }

    private enum Loaded: Sendable {
        case gridImage(CGImage)
        case fullImage(CGImage)
    }

    @ObservationIgnored private var previewStorage: CGImage??
    @ObservationIgnored private var cachedGridStorage: CGImage??
    private var loadedState: State?
    private let photo: Photo
    private let images: PhotoImages
    private let gridSize: ImageSize

    init(photo: Photo, images: PhotoImages, gridSize: ImageSize) {
        self.photo = photo
        self.images = images
        self.gridSize = gridSize
    }

    var preview: CGImage? {
        if let previewStorage { return previewStorage }
        let preview = images.preview(photo)
        previewStorage = .some(preview)
        return preview
    }

    var state: State {
        if let loadedState { return loadedState }
        if let cached = cachedGridImage { return .gridImage(cached) }
        return .preview
    }

    var isFullImageShown: Bool {
        if case .fullImage = state { return true }
        return false
    }

    func load(fitting size: FittingSize) async {
        let needsGridImage = state == .preview
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

    func release() {
        loadedState = nil
        cachedGridStorage = nil
    }

    private func apply(_ loaded: Loaded?) {
        switch loaded {
        case .gridImage(let image)?:
            if case .preview = state { loadedState = .gridImage(image) }
        case .fullImage(let image)?:
            loadedState = .fullImage(image)
        case nil:
            break
        }
    }

    private var cachedGridImage: CGImage? {
        if let cachedGridStorage { return cachedGridStorage }
        let cached = images.cachedImage(photo, gridSize)
        cachedGridStorage = .some(cached)
        return cached
    }
}
