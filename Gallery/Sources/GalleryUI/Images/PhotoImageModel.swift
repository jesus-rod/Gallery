import CoreGraphics
import GalleryCore
import Observation

@Observable
@MainActor
final class PhotoImageModel {
    @ObservationIgnored private var previewStorage: CGImage??
    @ObservationIgnored private var cachedStorage: CGImage??
    private var loadedImage: CGImage?
    private let photo: Photo
    private let images: PhotoImages
    private let size: ImageSize

    init(photo: Photo, images: PhotoImages, size: ImageSize) {
        self.photo = photo
        self.images = images
        self.size = size
    }

    var preview: CGImage? {
        if let previewStorage { return previewStorage }
        let preview = images.preview(photo)
        previewStorage = .some(preview)
        return preview
    }

    var image: CGImage? {
        loadedImage ?? cachedImage
    }

    var wasCachedOnAppear: Bool {
        cachedImage != nil
    }

    var isLoaded: Bool {
        image != nil
    }

    func load(size: ImageSize) async {
        if let cached = images.cachedImage(photo, size) {
            loadedImage = cached
            return
        }
        guard let loaded = try? await images.image(photo, size), !Task.isCancelled else { return }
        loadedImage = loaded
    }

    func release() {
        loadedImage = nil
        cachedStorage = nil
    }

    private var cachedImage: CGImage? {
        if let cachedStorage { return cachedStorage }
        let cached = images.cachedImage(photo, size)
        cachedStorage = .some(cached)
        return cached
    }
}
