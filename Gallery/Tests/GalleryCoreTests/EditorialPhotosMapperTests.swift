import Foundation
import GalleryCore
import Testing

struct EditorialPhotosMapperTests {
    @Test(arguments: [199, 201, 300, 400, 500])
    func map_throwsInvalidDataOnNon200Response(statusCode: Int) throws {
        let json = makeJSON([])

        #expect(throws: UnsplashAPIError.invalidData) {
            try EditorialPhotosMapper.map(json, from: HTTPURLResponse(statusCode: statusCode))
        }
    }

    @Test func map_throwsInvalidDataOn200ResponseWithInvalidJSON() {
        let invalidJSON = Data("invalid json".utf8)

        #expect(throws: UnsplashAPIError.invalidData) {
            try EditorialPhotosMapper.map(invalidJSON, from: HTTPURLResponse(statusCode: 200))
        }
    }

    @Test func map_deliversEmptyPageOn200ResponseWithEmptyJSONList() throws {
        let page = try EditorialPhotosMapper.map(makeJSON([]), from: HTTPURLResponse(statusCode: 200))

        #expect(page == PhotoPage(photos: [], totalPages: nil))
    }

    @Test func map_deliversPhotosOn200ResponseWithJSONItems() throws {
        let item1 = makePhoto(
            id: "a-id",
            blurHash: "LoC%a7IoIVxZ_NM|M{s:%hRjWAo0",
            description: "A man drinking a coffee.",
            altDescription: "a man holding a cup of coffee"
        )
        let item2 = makePhoto(id: "another-id", blurHash: nil, description: nil, altDescription: nil)

        let page = try EditorialPhotosMapper.map(
            makeJSON([item1.json, item2.json]), from: HTTPURLResponse(statusCode: 200))

        #expect(page == PhotoPage(photos: [item1.model, item2.model], totalPages: nil))
    }

    private func makeJSON(_ items: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: items)
    }
}

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
