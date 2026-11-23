import Foundation

public enum SearchPhotosMapper {
    private struct Root: Decodable {
        let totalPages: Int
        let results: [RemotePhoto]
    }

    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> PhotoPage {
        let root = try response.requireDecodable(Root.self, from: data)
        return PhotoPage(photos: root.results.map(\.photo), totalPages: root.totalPages)
    }
}
