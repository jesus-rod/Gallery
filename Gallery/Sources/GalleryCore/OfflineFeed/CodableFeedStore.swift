import Foundation

public actor CodableFeedStore: FeedStore {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func retrieve() async throws -> [Photo] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        guard try decoder.decode(Header.self, from: data).version == Envelope.currentVersion else { return [] }
        return try decoder.decode(Envelope.self, from: data).photos.map(\.model)
    }

    public func save(_ photos: [Photo]) async throws {
        let envelope = Envelope(version: Envelope.currentVersion, photos: photos.map(LocalPhoto.init))
        let data = try JSONEncoder().encode(envelope)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}

private struct Header: Decodable {
    let version: Int
}

private struct Envelope: Codable {
    static let currentVersion = 1

    let version: Int
    let photos: [LocalPhoto]
}

private struct LocalPhoto: Codable {
    let id: String
    let width: Int
    let height: Int
    let blurHash: String?
    let description: String?
    let altDescription: String?
    let renditions: LocalRenditions
    let photographer: LocalPhotographer

    init(_ photo: Photo) {
        id = photo.id
        width = photo.width
        height = photo.height
        blurHash = photo.blurHash
        description = photo.description
        altDescription = photo.altDescription
        renditions = LocalRenditions(photo.renditions)
        photographer = LocalPhotographer(photo.photographer)
    }

    var model: Photo {
        Photo(
            id: id,
            width: width,
            height: height,
            blurHash: blurHash,
            description: description,
            altDescription: altDescription,
            renditions: renditions.model,
            photographer: photographer.model
        )
    }
}

private struct LocalRenditions: Codable {
    let raw: URL
    let small: URL
    let regular: URL

    init(_ renditions: Photo.Renditions) {
        raw = renditions.raw
        small = renditions.small
        regular = renditions.regular
    }

    var model: Photo.Renditions {
        Photo.Renditions(raw: raw, small: small, regular: regular)
    }
}

private struct LocalPhotographer: Codable {
    let name: String
    let profileURL: URL

    init(_ photographer: Photo.Photographer) {
        name = photographer.name
        profileURL = photographer.profileURL
    }

    var model: Photo.Photographer {
        Photo.Photographer(name: name, profileURL: profileURL)
    }
}
