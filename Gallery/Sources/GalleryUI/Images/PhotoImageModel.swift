import CoreGraphics
import GalleryCore
import Observation

@Observable
@MainActor
final class PhotoImageModel {
    enum State: Equatable {
        case preview(CGImage?)
        case image(CGImage)
    }

    private(set) var state: State
    private let photo: Photo
    private let images: PhotoImages

    init(photo: Photo, images: PhotoImages) {
        self.photo = photo
        self.images = images
        self.state = .preview(images.preview(photo))
    }

    var isLoaded: Bool {
        if case .image = state { return true }
        return false
    }

    func load(size: ImageSize) async {
        guard let image = try? await images.image(photo, size) else { return }
        state = .image(image)
    }
}
