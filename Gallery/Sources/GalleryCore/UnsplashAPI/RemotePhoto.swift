import Foundation

struct RemotePhoto: Decodable {
    let id: String
    let width: Int
    let height: Int
    let blurHash: String?
    let description: String?
    let altDescription: String?
    let urls: URLs
    let user: User
    let links: Links

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
            photographer: Photo.Photographer(name: user.name, profileURL: user.links.html),
            pageURL: links.html
        )
    }
}

extension JSONDecoder {
    static var unsplash: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
