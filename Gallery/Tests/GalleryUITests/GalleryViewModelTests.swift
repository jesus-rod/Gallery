import Foundation
import GalleryCore
import Testing

@testable import GalleryUI

@MainActor
@Suite(.trackingLeaks)
struct GalleryViewModelTests {
    @Test func init_startsLoadingWithoutRequestingTheFeed() {
        let (sut, loader) = makeSUT()

        #expect(sut.feed == .loading)
        #expect(loader.loadFeedCallCount == 0)
    }

    @Test func load_deliversTheFirstPageWithAnIdleFooterWhenMoreCanLoad() async {
        let (sut, loader) = makeSUT()
        let photos = makePhotos(1...3)
        loader.stubFeed(.success(loader.page(photos)))

        await sut.load()

        #expect(loader.loadFeedCallCount == 1)
        #expect(sut.feed == .loaded(photos: photos, footer: .idle))
    }

    @Test func load_deliversTheFirstPageWithAnEndFooterWhenNothingMoreCanLoad() async {
        let (sut, loader) = makeSUT()
        let photos = makePhotos(1...3)
        loader.stubFeed(.success(loader.page(photos, hasMore: false)))

        await sut.load()

        #expect(sut.feed == .loaded(photos: photos, footer: .end))
    }

    @Test(arguments: [
        (UnsplashAPIError.rateLimited as any Error & Sendable, LoadError.rateLimited),
        (URLError(.notConnectedToInternet), .offline),
        (URLError(.networkConnectionLost), .offline),
        (URLError(.dataNotAllowed), .offline),
        (URLError(.timedOut), .offline),
        (URLError(.badServerResponse), .generic),
        (UnsplashAPIError.invalidData, .generic),
        (AnyError(), .generic),
    ])
    func load_failsWithTheMappedError(error: any Error & Sendable, expected: LoadError) async {
        let (sut, loader) = makeSUT()
        loader.stubFeed(.failure(error))

        await sut.load()

        #expect(sut.feed == .failed(expected))
    }

    @Test func retry_afterAFailedFirstPageRequestsTheFeedAgain() async {
        let (sut, loader) = makeSUT()
        let photos = makePhotos(1...2)
        loader.stubFeed(.failure(AnyError()))
        loader.stubFeed(.success(loader.page(photos, hasMore: false)))

        await sut.load()
        await sut.retry()

        #expect(loader.loadFeedCallCount == 2)
        #expect(sut.feed == .loaded(photos: photos, footer: .end))
    }

    @Test func retry_showsLoadingWhileTheFeedIsRequested() async {
        let (sut, loader) = makeSUT()
        let gate = Gate()
        loader.stubFeed(.failure(AnyError()))
        loader.stubFeed(.success(loader.page([], hasMore: false)), gate: gate)
        await sut.load()

        let retry = Task { await sut.retry() }
        await gate.untilReached()

        #expect(sut.feed == .loading)
        gate.open()
        await retry.value
    }

    @Test func photoAppeared_withinTheLastSixPhotosLoadsMoreAndAppends() async {
        let (sut, loader) = makeSUT()
        let firstPage = makePhotos(1...10)
        let secondPage = makePhotos(11...12)
        loader.stubFeed(.success(loader.page(firstPage)))
        loader.stubLoadMore(.success(loader.page(firstPage + secondPage)))
        await sut.load()

        await sut.photoAppeared(firstPage[4])

        #expect(loader.loadMoreCallCount == 1)
        #expect(sut.feed == .loaded(photos: firstPage + secondPage, footer: .idle))
    }

    @Test func photoAppeared_beforeTheLastSixPhotosDoesNotLoadMore() async {
        let (sut, loader) = makeSUT()
        let firstPage = makePhotos(1...10)
        loader.stubFeed(.success(loader.page(firstPage)))
        await sut.load()

        await sut.photoAppeared(firstPage[3])

        #expect(loader.loadMoreCallCount == 0)
        #expect(sut.feed == .loaded(photos: firstPage, footer: .idle))
    }

    @Test func photoAppeared_whileLoadingMoreShowsALoadingFooterAndDoesNotLoadAgain() async {
        let (sut, loader) = makeSUT()
        let firstPage = makePhotos(1...10)
        let gate = Gate()
        loader.stubFeed(.success(loader.page(firstPage)))
        loader.stubLoadMore(.success(loader.page(firstPage + makePhotos(11...12))), gate: gate)
        await sut.load()

        let loadingMore = Task { await sut.photoAppeared(firstPage[9]) }
        await gate.untilReached()
        await sut.photoAppeared(firstPage[8])

        #expect(loader.loadMoreCallCount == 1)
        #expect(sut.feed == .loaded(photos: firstPage, footer: .loading))
        gate.open()
        await loadingMore.value
    }

    @Test func photoAppeared_loadMoreFailureKeepsThePhotosAndShowsAFailedFooter() async {
        let (sut, loader) = makeSUT()
        let firstPage = makePhotos(1...10)
        loader.stubFeed(.success(loader.page(firstPage)))
        loader.stubLoadMore(.failure(URLError(.notConnectedToInternet)))
        await sut.load()

        await sut.photoAppeared(firstPage[9])

        #expect(sut.feed == .loaded(photos: firstPage, footer: .failed(.offline)))
    }

    @Test func retry_afterALoadMoreFailureCallsTheSameLoadMoreAgain() async {
        let (sut, loader) = makeSUT()
        let firstPage = makePhotos(1...10)
        let secondPage = makePhotos(11...12)
        loader.stubFeed(.success(loader.page(firstPage)))
        loader.stubLoadMore(.failure(AnyError()))
        loader.stubLoadMore(.success(loader.page(firstPage + secondPage, hasMore: false)))
        await sut.load()
        await sut.photoAppeared(firstPage[9])

        await sut.retry()

        #expect(loader.loadFeedCallCount == 1)
        #expect(loader.loadMoreCallCount == 2)
        #expect(sut.feed == .loaded(photos: firstPage + secondPage, footer: .end))
    }

    @Test func photoAppeared_atTheEndOfTheStreamRequestsNothing() async {
        let (sut, loader) = makeSUT()
        let photos = makePhotos(1...3)
        loader.stubFeed(.success(loader.page(photos, hasMore: false)))
        await sut.load()

        await sut.photoAppeared(photos[2])
        await sut.retry()

        #expect(loader.loadFeedCallCount == 1)
        #expect(loader.loadMoreCallCount == 0)
        #expect(sut.feed == .loaded(photos: photos, footer: .end))
    }

    @Test func refresh_replacesThePhotosWithTheFirstPage() async {
        let (sut, loader) = makeSUT()
        let refreshed = makePhotos(20...21)
        loader.stubFeed(.success(loader.page(makePhotos(1...10))))
        loader.stubFeed(.success(loader.page(refreshed, hasMore: false)))
        await sut.load()

        await sut.refresh()

        #expect(loader.loadFeedCallCount == 2)
        #expect(sut.feed == .loaded(photos: refreshed, footer: .end))
    }

    @Test func refresh_failureKeepsThePhotosAndExposesTheError() async {
        let (sut, loader) = makeSUT()
        let photos = makePhotos(1...10)
        loader.stubFeed(.success(loader.page(photos)))
        loader.stubFeed(.failure(UnsplashAPIError.rateLimited))
        await sut.load()

        await sut.refresh()

        #expect(sut.feed == .loaded(photos: photos, footer: .idle))
        #expect(sut.refreshError == .rateLimited)
    }

    @Test func refreshError_clearsOnDismissAndOnTheNextRefresh() async {
        let (sut, loader) = makeSUT()
        loader.stubFeed(.success(loader.page(makePhotos(1...10))))
        loader.stubFeed(.failure(AnyError()))
        loader.stubFeed(.failure(AnyError()))
        loader.stubFeed(.success(loader.page(makePhotos(1...10))))
        await sut.load()

        await sut.refresh()
        sut.dismissRefreshError()
        #expect(sut.refreshError == nil)

        await sut.refresh()
        await sut.refresh()
        #expect(sut.refreshError == nil)
    }

    @Test func refresh_discardsALoadMoreThatCompletesAfterIt() async {
        let (sut, loader) = makeSUT()
        let firstPage = makePhotos(1...10)
        let refreshed = makePhotos(20...21)
        let gate = Gate()
        loader.stubFeed(.success(loader.page(firstPage)))
        loader.stubLoadMore(.success(loader.page(firstPage + makePhotos(11...12))), gate: gate)
        loader.stubFeed(.success(loader.page(refreshed, hasMore: false)))
        await sut.load()

        let lateLoadMore = Task { await sut.photoAppeared(firstPage[9]) }
        await gate.untilReached()
        await sut.refresh()
        gate.open()
        await lateLoadMore.value

        #expect(sut.feed == .loaded(photos: refreshed, footer: .end))
    }

    @Test func init_hasNoSearchResults() {
        let (sut, loader) = makeSUT()

        #expect(sut.searchResults == nil)
        #expect(loader.searchQueries.isEmpty)
    }

    @Test func search_requestsTheFirstPageForTheTrimmedQuery() async {
        let (sut, loader) = makeSUT()
        loader.stubSearch(.success(loader.page([], hasMore: false)))

        await sut.search("  cats \n")

        #expect(loader.searchQueries == ["cats"])
    }

    @Test(arguments: ["", "   ", " \n\t "])
    func search_withAnEmptyOrWhitespaceQueryDoesNothing(query: String) async {
        let (sut, loader) = makeSUT()

        await sut.search(query)

        #expect(loader.searchQueries.isEmpty)
        #expect(sut.searchResults == nil)
    }

    @Test func search_showsLoadingWithTheQueryWhileTheFirstPageLoads() async {
        let (sut, loader) = makeSUT()
        let gate = Gate()
        loader.stubSearch(.success(loader.page([], hasMore: false)), gate: gate)

        let search = Task { await sut.search("cats") }
        await gate.untilReached()

        #expect(sut.searchResults == SearchResults(query: "cats", state: .loading))
        gate.open()
        await search.value
    }

    @Test func search_deliversTheFirstPageWithAnIdleFooterWhenMoreCanLoad() async {
        let (sut, loader) = makeSUT()
        let photos = makePhotos(1...3)
        loader.stubSearch(.success(loader.page(photos)))

        await sut.search("cats")

        #expect(sut.searchResults == SearchResults(query: "cats", state: .loaded(photos: photos, footer: .idle)))
    }

    @Test func search_deliversTheFirstPageWithAnEndFooterWhenNothingMoreCanLoad() async {
        let (sut, loader) = makeSUT()
        let photos = makePhotos(1...3)
        loader.stubSearch(.success(loader.page(photos, hasMore: false)))

        await sut.search("cats")

        #expect(sut.searchResults == SearchResults(query: "cats", state: .loaded(photos: photos, footer: .end)))
    }

    @Test func search_deliversNoPhotosAsLoadedWithAnEndFooter() async {
        let (sut, loader) = makeSUT()
        loader.stubSearch(.success(loader.page([], hasMore: false)))

        await sut.search("cats")

        #expect(sut.searchResults == SearchResults(query: "cats", state: .loaded(photos: [], footer: .end)))
    }

    @Test(arguments: [
        (UnsplashAPIError.rateLimited as any Error & Sendable, LoadError.rateLimited),
        (URLError(.notConnectedToInternet), .offline),
        (AnyError(), .generic),
    ])
    func search_failsWithTheMappedError(error: any Error & Sendable, expected: LoadError) async {
        let (sut, loader) = makeSUT()
        loader.stubSearch(.failure(error))

        await sut.search("cats")

        #expect(sut.searchResults == SearchResults(query: "cats", state: .failed(expected)))
    }

    @Test func search_withTheQueryAlreadyShownDoesNotRequestAgain() async {
        let (sut, loader) = makeSUT()
        loader.stubSearch(.success(loader.page([], hasMore: false)))

        await sut.search("cats")
        await sut.search(" cats ")

        #expect(loader.searchQueries == ["cats"])
    }

    @Test func search_doesNotChangeTheFeed() async {
        let (sut, loader) = makeSUT()
        let feedPhotos = makePhotos(1...4)
        loader.stubFeed(.success(loader.page(feedPhotos, hasMore: false)))
        loader.stubSearch(.success(loader.page([], hasMore: false)))
        await sut.load()

        await sut.search("cats")

        #expect(sut.feed == .loaded(photos: feedPhotos, footer: .end))
        #expect(loader.loadFeedCallCount == 1)
    }

    @Test func retrySearch_afterAFailedFirstPageRequestsTheSameQueryAgain() async {
        let (sut, loader) = makeSUT()
        let photos = makePhotos(1...2)
        loader.stubSearch(.failure(AnyError()))
        loader.stubSearch(.success(loader.page(photos, hasMore: false)))
        await sut.search("cats")

        await sut.retrySearch()

        #expect(loader.searchQueries == ["cats", "cats"])
        #expect(sut.searchResults == SearchResults(query: "cats", state: .loaded(photos: photos, footer: .end)))
    }

    @Test func retrySearch_withoutASearchDoesNothing() async {
        let (sut, loader) = makeSUT()

        await sut.retrySearch()

        #expect(loader.searchQueries.isEmpty)
        #expect(sut.searchResults == nil)
    }

    private func makeSUT(sourceLocation: SourceLocation = #_sourceLocation) -> (GalleryViewModel, FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let sut = GalleryViewModel(loadFeed: loader.loadFeed, search: loader.search)
        trackForMemoryLeaks(loader, sourceLocation: sourceLocation)
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        return (sut, loader)
    }
}
