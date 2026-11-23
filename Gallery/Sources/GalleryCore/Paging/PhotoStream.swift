public struct PhotoStream: Sendable {
    public typealias PageLoader = @Sendable (Int) async throws -> PhotoPage

    private let loadPage: PageLoader

    public init(loadPage: @escaping PageLoader) {
        self.loadPage = loadPage
    }

    public func firstPage() async throws -> Paginated<Photo> {
        try await load(page: 1, after: [], seenIDs: [])
    }

    private func load(page number: Int, after loaded: [Photo], seenIDs: Set<String>) async throws -> Paginated<Photo> {
        let page = try await loadPage(number)
        var seenIDs = seenIDs
        let items = loaded + page.photos.filter { seenIDs.insert($0.id).inserted }
        guard hasMore(after: page, number: number) else {
            return Paginated(items: items)
        }
        return Paginated(
            items: items,
            loadMore: { [seenIDs] in try await load(page: number + 1, after: items, seenIDs: seenIDs) }
        )
    }

    private func hasMore(after page: PhotoPage, number: Int) -> Bool {
        guard !page.photos.isEmpty else { return false }
        guard let totalPages = page.totalPages else { return true }
        return number < totalPages
    }
}
