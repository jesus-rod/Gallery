import Foundation

public enum EditorialPhotosMapper {
    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> PhotoPage {
        guard response.statusCode == 200, let items = try? JSONDecoder.unsplash.decode([RemotePhoto].self, from: data)
        else {
            throw UnsplashAPIError.invalidData
        }
        return PhotoPage(photos: items.map(\.photo), totalPages: nil)
    }
}
