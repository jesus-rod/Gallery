import Foundation

public enum EditorialPhotosMapper {
    private struct RemotePhoto: Decodable {
        let id: String
        let width: Int
        let height: Int
        let blurHash: String?
        let description: String?
        let altDescription: String?
        let urls: URLs
        let user: User

        struct URLs: Decodable {
            let raw: URL
            let small: URL
            let regular: URL
        }

        struct User: Decodable {
            let name: String
            let links: Links
        }

        struct Links: Decodable {
            let html: URL
        }

        var photo: Photo {
            Photo(
                id: id,
                width: width,
                height: height,
                blurHash: blurHash,
                description: description,
                altDescription: altDescription,
                renditions: Photo.Renditions(raw: urls.raw, small: urls.small, regular: urls.regular),
                photographer: Photo.Photographer(name: user.name, profileURL: user.links.html)
            )
        }
    }

    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> PhotoPage {
        guard response.statusCode == 200, let items = try? decoder.decode([RemotePhoto].self, from: data) else {
            throw UnsplashAPIError.invalidData
        }
        return PhotoPage(photos: items.map(\.photo), totalPages: nil)
    }
}

extension EditorialPhotosMapper {
    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
