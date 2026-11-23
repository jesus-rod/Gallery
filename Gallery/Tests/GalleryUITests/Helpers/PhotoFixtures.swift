import Foundation
import GalleryCore

func makePhoto(
    id: String = "any-id",
    width: Int = 1,
    height: Int = 1,
    description: String? = nil,
    altDescription: String? = nil
) -> Photo {
    Photo(
        id: id,
        width: width,
        height: height,
        blurHash: nil,
        description: description,
        altDescription: altDescription,
        renditions: Photo.Renditions(
            raw: URL(string: "https://images.unsplash.com/\(id)/raw")!,
            small: URL(string: "https://images.unsplash.com/\(id)/small")!,
            regular: URL(string: "https://images.unsplash.com/\(id)/regular")!
        ),
        photographer: Photo.Photographer(name: "A photographer", profileURL: URL(string: "https://unsplash.com/@a")!),
        pageURL: URL(string: "https://unsplash.com/photos/\(id)")!
    )
}

func makePhotos(_ range: ClosedRange<Int>) -> [Photo] {
    range.map { makePhoto(id: "\($0)") }
}

struct AnyError: Error {}
