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

    private func makeSUT(sourceLocation: SourceLocation = #_sourceLocation) -> (GalleryViewModel, FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let sut = GalleryViewModel(loadFeed: loader.loadFeed)
        trackForMemoryLeaks(loader, sourceLocation: sourceLocation)
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        return (sut, loader)
    }
}
