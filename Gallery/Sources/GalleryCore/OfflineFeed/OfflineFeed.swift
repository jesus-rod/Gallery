public enum OfflineFeed {
    public typealias LoadFirstPage = @Sendable () async throws -> Paginated<Photo>

    public static let defaultLimit = 300

    public static func saving(
        _ load: @escaping LoadFirstPage,
        to store: FeedStore,
        limit: Int = defaultLimit
    ) -> LoadFirstPage {
        {
            let page = try await load()
            return await saved(page, to: store, limit: limit, isFull: false)
        }
    }

    private static func saved(
        _ page: Paginated<Photo>,
        to store: FeedStore,
        limit: Int,
        isFull: Bool
    ) async -> Paginated<Photo> {
        if !isFull {
            try? await store.save(Array(page.items.prefix(limit)))
        }
        let isNowFull = isFull || page.items.count >= limit
        guard let loadMore = page.loadMore else { return page }
        return Paginated(
            items: page.items,
            loadMore: {
                let next = try await loadMore()
                return await saved(next, to: store, limit: limit, isFull: isNowFull)
            })
    }
}
