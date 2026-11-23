public struct Paginated<Item: Sendable>: Sendable {
    public typealias LoadMore = @Sendable () async throws -> Paginated<Item>

    public let items: [Item]
    public let loadMore: LoadMore?

    public init(items: [Item], loadMore: LoadMore? = nil) {
        self.items = items
        self.loadMore = loadMore
    }
}
