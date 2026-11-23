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

    @Test func map_throwsRateLimitedOn403ResponseWithNoRemainingRequests() {
        let response = HTTPURLResponse(statusCode: 403, headers: ["X-Ratelimit-Remaining": "0"])

        #expect(throws: UnsplashAPIError.rateLimited) {
            try EditorialPhotosMapper.map(Data("Rate Limit Exceeded".utf8), from: response)
        }
    }

    @Test(arguments: [[:], ["X-Ratelimit-Remaining": "12"]])
    func map_throwsInvalidDataOn403ResponseWithRemainingRequests(headers: [String: String]) {
        let response = HTTPURLResponse(statusCode: 403, headers: headers)

        #expect(throws: UnsplashAPIError.invalidData) {
            try EditorialPhotosMapper.map(Data("Forbidden".utf8), from: response)
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
