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

    private func makeSUT(sourceLocation: SourceLocation = #_sourceLocation) -> (GalleryViewModel, FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let sut = GalleryViewModel(loadFeed: loader.loadFeed)
        trackForMemoryLeaks(loader, sourceLocation: sourceLocation)
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        return (sut, loader)
    }
}
