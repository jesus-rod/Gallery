import Foundation

public struct Photo: Hashable, Sendable {
    public let id: String
    public let width: Int
    public let height: Int
    public let blurHash: String?
    public let description: String?
    public let altDescription: String?
    public let renditions: Renditions
    public let photographer: Photographer
    public let pageURL: URL

    public init(
        id: String,
        width: Int,
        height: Int,
        blurHash: String?,
        description: String?,
        altDescription: String?,
        renditions: Renditions,
        photographer: Photographer,
        pageURL: URL
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.blurHash = blurHash
        self.description = description
        self.altDescription = altDescription
        self.renditions = renditions
        self.photographer = photographer
        self.pageURL = pageURL
    }
}

extension Photo {
    public struct Renditions: Hashable, Sendable {
        public let raw: URL
        public let small: URL
        public let regular: URL

        public init(raw: URL, small: URL, regular: URL) {
            self.raw = raw
            self.small = small
            self.regular = regular
        }
    }

    public struct Photographer: Hashable, Sendable {
        public let name: String
        public let profileURL: URL

        public init(name: String, profileURL: URL) {
            self.name = name
            self.profileURL = profileURL
        }
    }
}
