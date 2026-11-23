import Foundation
import GalleryCore
import Testing

@Suite(.trackingLeaks)
struct OfflineFeedTests {
    @Test func saving_savesTheItemsOfASuccessfulFirstPage() async throws {
        let photos = [makePhoto(id: "1").model, makePhoto(id: "2").model]
        let store = makeStore()
        let sut = makeSUT(store: store, load: { Paginated(items: photos) })

        let loaded = try await sut()

        #expect(loaded.items == photos)
        #expect(await store.saved == [photos])
    }

    @Test func saving_savesNothingAndRethrowsWhenTheFirstPageFails() async {
        let store = makeStore()
        let sut = makeSUT(store: store, load: { throw URLError(.notConnectedToInternet) })

        await #expect(throws: URLError(.notConnectedToInternet)) { try await sut() }

        #expect(await store.saved.isEmpty)
    }

    @Test func saving_savesEveryItemLoadedSoFarOnLoadMore() async throws {
        let page1 = [makePhoto(id: "1").model, makePhoto(id: "2").model]
        let page2 = [makePhoto(id: "3").model]
        let store = makeStore()
        let all = page1 + page2
        let sut = makeSUT(store: store, load: { Paginated(items: page1, loadMore: { Paginated(items: all) }) })

        let first = try await sut()
        let loadMore = try #require(first.loadMore)
        let second = try await loadMore()

        #expect(second.items == page1 + page2)
        #expect(await store.saved == [page1, page1 + page2])
    }

    @Test func saving_savesOnlyTheFirstPhotosUpToTheLimit() async throws {
        let photos = (1...5).map { makePhoto(id: "\($0)").model }
        let store = makeStore()
        let sut = makeSUT(store: store, limit: 3, load: { Paginated(items: photos) })

        _ = try await sut()

        #expect(await store.saved == [Array(photos.prefix(3))])
    }

    @Test func saving_savesNothingMoreOnceTheLimitWasReached() async throws {
        let page1 = (1...3).map { makePhoto(id: "\($0)").model }
        let all = page1 + [makePhoto(id: "4").model]
        let store = makeStore()
        let sut = makeSUT(
            store: store, limit: 3, load: { Paginated(items: page1, loadMore: { Paginated(items: all) }) })

        let first = try await sut()
        let loadMore = try #require(first.loadMore)
        _ = try await loadMore()

        #expect(await store.saved == [page1])
    }

    @Test func saving_doesNotFailTheLoadWhenSavingFails() async throws {
        let photos = [makePhoto(id: "1").model]
        let store = makeStore(saveError: URLError(.cannotWriteToFile))
        let sut = makeSUT(store: store, load: { Paginated(items: photos, loadMore: { Paginated(items: photos) }) })

        let first = try await sut()
        let loadMore = try #require(first.loadMore)
        let second = try await loadMore()

        #expect(first.items == photos)
        #expect(second.items == photos)
    }

    @Test func saving_savesNothingNewAndRethrowsWhenLoadMoreFails() async throws {
        let photos = [makePhoto(id: "1").model]
        let store = makeStore()
        let sut = makeSUT(
            store: store, load: { Paginated(items: photos, loadMore: { throw URLError(.timedOut) }) })

        let first = try await sut()
        let loadMore = try #require(first.loadMore)

        await #expect(throws: URLError(.timedOut)) { try await loadMore() }
        #expect(await store.saved == [photos])
    }

    @Test func saving_hasNoLoadMoreWhenThereAreNoMorePages() async throws {
        let sut = makeSUT(store: makeStore(), load: { Paginated(items: [makePhoto(id: "1").model]) })

        let page = try await sut()

        #expect(page.loadMore == nil)
    }

    private func makeStore(saveError: Error? = nil) -> FeedStoreSpy {
        let store = FeedStoreSpy(saveError: saveError)
        trackForMemoryLeaks(store)
        return store
    }

    private func makeSUT(
        store: FeedStoreSpy,
        limit: Int = OfflineFeed.defaultLimit,
        load: @escaping OfflineFeed.LoadFirstPage
    ) -> OfflineFeed.LoadFirstPage {
        OfflineFeed.saving(load, to: store, limit: limit)
    }
}
