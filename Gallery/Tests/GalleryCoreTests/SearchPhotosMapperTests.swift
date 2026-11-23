import Foundation
import GalleryCore
import Testing

struct SearchPhotosMapperTests {
    @Test(arguments: [199, 201, 300, 400, 500])
    func map_throwsInvalidDataOnNon200Response(statusCode: Int) throws {
        let json = makeJSON(totalPages: 0, results: [])

        #expect(throws: UnsplashAPIError.invalidData) {
            try SearchPhotosMapper.map(json, from: HTTPURLResponse(statusCode: statusCode))
        }
    }

    @Test func map_throwsInvalidDataOn200ResponseWithInvalidJSON() {
        let invalidJSON = Data("invalid json".utf8)

        #expect(throws: UnsplashAPIError.invalidData) {
            try SearchPhotosMapper.map(invalidJSON, from: HTTPURLResponse(statusCode: 200))
        }
    }

    @Test func map_deliversEmptyPageOn200ResponseWithEmptyResults() throws {
        let page = try SearchPhotosMapper.map(
            makeJSON(totalPages: 0, results: []), from: HTTPURLResponse(statusCode: 200))

        #expect(page == PhotoPage(photos: [], totalPages: 0))
    }

    @Test func map_deliversPhotosAndTotalPagesOn200ResponseWithJSONResults() throws {
        let item1 = makePhoto(
            id: "a-id",
            blurHash: "LoC%a7IoIVxZ_NM|M{s:%hRjWAo0",
            description: "A man drinking a coffee.",
            altDescription: "a man holding a cup of coffee"
        )
        let item2 = makePhoto(id: "another-id")

        let page = try SearchPhotosMapper.map(
            makeJSON(totalPages: 7, results: [item1.json, item2.json]), from: HTTPURLResponse(statusCode: 200))

        #expect(page == PhotoPage(photos: [item1.model, item2.model], totalPages: 7))
    }

    private func makeJSON(totalPages: Int, results: [[String: Any]]) -> Data {
        let root: [String: Any] = ["total": results.count, "total_pages": totalPages, "results": results]
        return try! JSONSerialization.data(withJSONObject: root)
    }
}
