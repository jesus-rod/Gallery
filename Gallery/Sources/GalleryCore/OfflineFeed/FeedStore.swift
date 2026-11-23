public protocol FeedStore: Sendable {
    func retrieve() async throws -> [Photo]
    func save(_ photos: [Photo]) async throws
}
