public struct PhotoPage: Equatable, Sendable {
    public let photos: [Photo]
    public let totalPages: Int?

    public init(photos: [Photo], totalPages: Int?) {
        self.photos = photos
        self.totalPages = totalPages
    }
}
