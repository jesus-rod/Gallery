import Foundation
import Testing

@testable import GalleryImageLoading

@Suite(.trackingLeaks)
struct InFlightDedupImageDataLoaderTests {
    private let url = URL(string: "https://images.example.com/a")!
    private let otherURL = URL(string: "https://images.example.com/b")!

    @Test func concurrentLoadsOfSameURL_requestUpstreamOnceAndDeliverDataToEveryCaller() async throws {
        let (sut, spy) = makeSUT()
        let data = anyData()

        let first = Task { try await sut.loadImageData(from: url) }
        await spy.untilRequested(count: 1)
        let second = Task { try await sut.loadImageData(from: url) }
        await eventually { sut.waiterCount(for: url) == 2 }
        spy.complete(with: .success(data))

        #expect(try await first.value == data)
        #expect(try await second.value == data)
        #expect(spy.requestedURLs == [url])
    }

    @Test func upstreamError_reachesEveryCaller() async {
        let (sut, spy) = makeSUT()

        let first = Task { try await sut.loadImageData(from: url) }
        await spy.untilRequested(count: 1)
        let second = Task { try await sut.loadImageData(from: url) }
        await eventually { sut.waiterCount(for: url) == 2 }
        spy.complete(with: .failure(AnyError()))

        await #expect(throws: AnyError.self) { try await first.value }
        await #expect(throws: AnyError.self) { try await second.value }
    }

    @Test func differentURLs_loadIndependently() async throws {
        let (sut, spy) = makeSUT()

        let first = Task { try await sut.loadImageData(from: url) }
        await spy.untilRequested(count: 1)
        let second = Task { try await sut.loadImageData(from: otherURL) }
        await spy.untilRequested(count: 2)
        await spy.untilPending(count: 2)
        spy.complete(with: .success(Data("b".utf8)), at: 1)
        spy.complete(with: .success(Data("a".utf8)), at: 0)

        #expect(try await first.value == Data("a".utf8))
        #expect(try await second.value == Data("b".utf8))
        #expect(spy.requestedURLs == [url, otherURL])
    }

    @Test func oneOfTwoCallersCancelling_getsCancellationErrorWithoutCancellingTheSharedLoad() async throws {
        let (sut, spy) = makeSUT()
        let data = anyData()

        let cancelled = Task { try await sut.loadImageData(from: url) }
        await spy.untilRequested(count: 1)
        let waiting = Task { try await sut.loadImageData(from: url) }
        await eventually { sut.waiterCount(for: url) == 2 }

        cancelled.cancel()
        await #expect(throws: CancellationError.self) { try await cancelled.value }
        #expect(spy.cancelledURLs.isEmpty)

        spy.complete(with: .success(data))
        #expect(try await waiting.value == data)
    }

    @Test func everyCallerCancelling_cancelsTheUpstreamLoad() async {
        let (sut, spy) = makeSUT()

        let first = Task { try await sut.loadImageData(from: url) }
        await spy.untilRequested(count: 1)
        let second = Task { try await sut.loadImageData(from: url) }
        await eventually { sut.waiterCount(for: url) == 2 }
        await spy.untilPending(count: 1)

        first.cancel()
        second.cancel()

        await #expect(throws: CancellationError.self) { try await first.value }
        await #expect(throws: CancellationError.self) { try await second.value }
        await eventually { spy.cancelledURLs == [url] }
        #expect(spy.cancelledURLs == [url])
    }

    @Test func callerAlreadyCancelled_getsCancellationError() async {
        let (sut, _) = makeSUT()

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await sut.loadImageData(from: url)
        }

        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func completedLoad_isForgottenSoALaterLoadGoesUpstreamAgain() async throws {
        let (sut, spy) = makeSUT()

        let first = Task { try await sut.loadImageData(from: url) }
        await spy.untilPending(count: 1)
        spy.complete(with: .success(anyData()), at: 0)
        _ = try await first.value

        let second = Task { try await sut.loadImageData(from: url) }
        await spy.untilPending(count: 1)
        spy.complete(with: .success(anyData()), at: 1)
        _ = try await second.value

        #expect(spy.requestedURLs == [url, url])
        #expect(sut.waiterCount(for: url) == 0)
    }

    private func makeSUT(sourceLocation: SourceLocation = #_sourceLocation) -> (
        InFlightDedupImageDataLoader, ImageDataLoaderSpy
    ) {
        let spy = ImageDataLoaderSpy()
        let sut = InFlightDedupImageDataLoader(decoratee: spy)
        trackForMemoryLeaks(spy, sourceLocation: sourceLocation)
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        return (sut, spy)
    }
}
