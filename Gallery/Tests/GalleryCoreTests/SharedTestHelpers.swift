import Foundation
import GalleryCore

func makePhoto(
    id: String,
    blurHash: String? = nil,
    description: String? = nil,
    altDescription: String? = nil
) -> (model: Photo, json: [String: Any]) {
    let model = Photo(
        id: id,
        width: 5245,
        height: 3497,
        blurHash: blurHash,
        description: description,
        altDescription: altDescription,
        renditions: Photo.Renditions(
            raw: URL(string: "https://images.unsplash.com/\(id)?ixid=raw")!,
            small: URL(string: "https://images.unsplash.com/\(id)?w=400")!,
            regular: URL(string: "https://images.unsplash.com/\(id)?w=1080")!
        ),
        photographer: Photo.Photographer(
            name: "A photographer",
            profileURL: URL(string: "https://unsplash.com/@photographer-\(id)")!
        )
    )
    let json: [String: Any?] = [
        "id": id,
        "width": model.width,
        "height": model.height,
        "blur_hash": blurHash,
        "description": description,
        "alt_description": altDescription,
        "urls": [
            "raw": model.renditions.raw.absoluteString,
            "full": "https://images.unsplash.com/\(id)?full",
            "small": model.renditions.small.absoluteString,
            "regular": model.renditions.regular.absoluteString,
            "thumb": "https://images.unsplash.com/\(id)?thumb",
        ],
        "user": [
            "name": model.photographer.name,
            "links": ["html": model.photographer.profileURL.absoluteString],
        ],
    ]
    return (model, json.compactMapValues { $0 })
}

extension HTTPURLResponse {
    convenience init(statusCode: Int, headers: [String: String]? = nil) {
        self.init(
            url: URL(string: "https://any-url.com")!, statusCode: statusCode, httpVersion: nil, headerFields: headers)!
    }
}
