import CoreGraphics
import GalleryCore

enum ContentFit {
    static func size(of photo: Photo, in container: CGSize) -> CGSize {
        let aspectRatio = photo.width > 0 && photo.height > 0 ? Double(photo.width) / Double(photo.height) : 1
        let width = min(container.width, container.height * aspectRatio)
        return CGSize(width: width, height: width / aspectRatio)
    }
}
