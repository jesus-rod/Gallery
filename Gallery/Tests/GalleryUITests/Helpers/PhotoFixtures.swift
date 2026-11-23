import Foundation
import GalleryCore

func makePhoto(id: String = "any-id", description: String? = nil, altDescription: String? = nil) -> Photo {
    Photo(
        id: id,
        width: 1,
        height: 1,
        blurHash: nil,
        description: description,
        altDescription: altDescription,
        renditions: Photo.Renditions(
            raw: URL(string: "https://images.unsplash.com/\(id)/raw")!,
            small: URL(string: "https://images.unsplash.com/\(id)/small")!,
            regular: URL(string: "https://images.unsplash.com/\(id)/regular")!
        ),
        photographer: Photo.Photographer(name: "A photographer", profileURL: URL(string: "https://unsplash.com/@a")!)
    )
}

func makePhotos(_ range: ClosedRange<Int>) -> [Photo] {
    range.map { makePhoto(id: "\($0)") }
}

struct AnyError: Error {}
