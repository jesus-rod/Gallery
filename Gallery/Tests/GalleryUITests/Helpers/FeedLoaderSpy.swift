import GalleryCore
import Testing

@MainActor
final class FeedLoaderSpy {
    private struct Stub {
        let result: Result<Paginated<Photo>, Error>
        let gate: Gate?
    }

    private(set) var loadFeedCallCount = 0
    private(set) var loadMoreCallCount = 0
    private(set) var searchQueries: [String] = []
    private(set) var cancelledSearchQueries: [String] = []
    private(set) var cancelledLoadMoreCount = 0
    private var feedStubs: [Stub] = []
    private var loadMoreStubs: [Stub] = []
    private var searchStubs: [Stub] = []

    func stubFeed(_ result: Result<Paginated<Photo>, Error>, gate: Gate? = nil) {
        feedStubs.append(Stub(result: result, gate: gate))
    }

    func stubSearch(_ result: Result<Paginated<Photo>, Error>, gate: Gate? = nil) {
        searchStubs.append(Stub(result: result, gate: gate))
    }

    func stubLoadMore(_ result: Result<Paginated<Photo>, Error>, gate: Gate? = nil) {
        loadMoreStubs.append(Stub(result: result, gate: gate))
    }

    func page(_ photos: [Photo], hasMore: Bool = true) -> Paginated<Photo> {
        guard hasMore else { return Paginated(items: photos) }
        return Paginated(items: photos, loadMore: { try await self.loadMore() })
    }

    func loadFeed() async throws -> Paginated<Photo> {
        loadFeedCallCount += 1
        return try await resolve(next(from: &feedStubs, named: "loadFeed"))
    }

    func search(_ query: String) async throws -> Paginated<Photo> {
        searchQueries.append(query)
        let stub = next(from: &searchStubs, named: "search")
        await stub.gate?.pass()
        if Task.isCancelled { cancelledSearchQueries.append(query) }
        return try stub.result.get()
    }

    private func loadMore() async throws -> Paginated<Photo> {
        loadMoreCallCount += 1
        let stub = next(from: &loadMoreStubs, named: "loadMore")
        await stub.gate?.pass()
        if Task.isCancelled { cancelledLoadMoreCount += 1 }
        return try stub.result.get()
    }

    private func next(from stubs: inout [Stub], named name: String) -> Stub {
        guard !stubs.isEmpty else {
            Issue.record("Unexpected \(name) call with no stubbed result.")
            return Stub(result: .failure(AnyError()), gate: nil)
        }
        return stubs.removeFirst()
    }

    private func resolve(_ stub: Stub) async throws -> Paginated<Photo> {
        await stub.gate?.pass()
        return try stub.result.get()
    }
}
