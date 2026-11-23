import Foundation

public enum EditorialPhotosMapper {
    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> PhotoPage {
        let items = try response.requireDecodable([RemotePhoto].self, from: data)
        return PhotoPage(photos: items.map(\.photo), totalPages: nil)
    }
}
