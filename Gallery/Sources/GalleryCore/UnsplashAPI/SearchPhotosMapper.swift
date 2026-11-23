import Foundation

public enum SearchPhotosMapper {
    private struct Root: Decodable {
        let totalPages: Int
        let results: [RemotePhoto]
    }

    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> PhotoPage {
        guard response.statusCode == 200, let root = try? JSONDecoder.unsplash.decode(Root.self, from: data) else {
            throw UnsplashAPIError.invalidData
        }
        return PhotoPage(photos: root.results.map(\.photo), totalPages: root.totalPages)
    }
}
