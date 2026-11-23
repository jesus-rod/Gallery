import Foundation
import GalleryCore

struct PhotoDetails: Equatable {
    let caption: String
    let description: String?
    let size: String

    init(_ photo: Photo) {
        let caption = GalleryUI.caption(for: photo)
        self.caption = caption
        description = photo.description.flatMap { $0 == caption ? nil : $0 }
        size = "\(photo.width) × \(photo.height) · \(Self.megapixels(width: photo.width, height: photo.height)) MP"
    }

    private static func megapixels(width: Int, height: Int) -> String {
        let value = Double(width * height) / 1_000_000
        let rounded = value >= 10 ? value.rounded() : (value * 10).rounded() / 10
        return rounded == rounded.rounded() ? String(Int(rounded)) : String(format: "%.1f", rounded)
    }
}
