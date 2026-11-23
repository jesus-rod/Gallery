import Foundation
import GalleryCore

struct PhotoDetails: Equatable {
    let caption: String
    let description: String?
    let size: String

    init(_ photo: Photo, locale: Locale = .current) {
        let caption = GalleryUI.caption(for: photo)
        self.caption = caption
        description = photo.description.flatMap { $0 == caption ? nil : $0 }
        let megapixels = Self.megapixels(width: photo.width, height: photo.height, locale: locale)
        size = "\(photo.width) × \(photo.height) · \(megapixels) MP"
    }

    private static func megapixels(width: Int, height: Int, locale: Locale) -> String {
        let value = Double(width * height) / 1_000_000
        let rounded = value >= 10 ? value.rounded() : (value * 10).rounded() / 10
        return rounded.formatted(.number.precision(.fractionLength(0...1)).grouping(.never).locale(locale))
    }
}
