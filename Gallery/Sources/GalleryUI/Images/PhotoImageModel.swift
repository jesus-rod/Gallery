import CoreGraphics
import GalleryCore
import Observation

@Observable
@MainActor
final class PhotoImageModel {
    @ObservationIgnored private var previewStorage: CGImage??
    private(set) var image: CGImage?
    private let photo: Photo
    private let images: PhotoImages

    init(photo: Photo, images: PhotoImages) {
        self.photo = photo
        self.images = images
    }

    var preview: CGImage? {
        if let previewStorage { return previewStorage }
        let preview = images.preview(photo)
        previewStorage = .some(preview)
        return preview
    }

    var isLoaded: Bool {
        image != nil
    }

    func load(size: ImageSize) async {
        guard let loaded = try? await images.image(photo, size), !Task.isCancelled else { return }
        image = loaded
    }
}
