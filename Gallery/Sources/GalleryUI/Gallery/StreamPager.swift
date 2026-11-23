import GalleryCore
import Observation

@MainActor
@Observable
final class StreamPager {
    typealias LoadFirstPage = @Sendable () async throws -> Paginated<Photo>

    private(set) var state: StreamState = .loading
    private(set) var offlineReason: LoadError?

    @ObservationIgnored private let loadFirstPage: LoadFirstPage
    @ObservationIgnored private let loadOfflineFeed: (@Sendable () async -> [Photo])?
    @ObservationIgnored private var loadMore: Paginated<Photo>.LoadMore?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var cancelInFlight: (() -> Void)?

    init(
        loadFirstPage: @escaping LoadFirstPage,
        loadOfflineFeed: (@Sendable () async -> [Photo])? = nil
    ) {
        self.loadFirstPage = loadFirstPage
        self.loadOfflineFeed = loadOfflineFeed
    }

    func load() async {
        await run {
            do {
                self.showFirstPage(try await self.loadFirstPage())
            } catch {
                await self.showOfflineFeedOrFail(with: LoadError(error))
            }
        }
    }

    func cancel() {
        cancelInFlight?()
        cancelInFlight = nil
        generation += 1
    }

    func refresh() async -> LoadError? {
        cancel()
        if case .loaded(let photos, .loading) = state {
            state = .loaded(photos: photos, footer: .idle)
        }
        let generation = generation
        return await run {
            do {
                let page = try await self.loadFirstPage()
                guard generation == self.generation else { return nil }
                self.showFirstPage(page)
                return nil
            } catch {
                guard generation == self.generation else { return nil }
                return LoadError(error)
            }
        }
    }

    func retry() async {
        switch state {
        case .failed:
            state = .loading
            await load()
        case .loaded(let photos, .failed):
            await run { await self.loadMore(after: photos) }
        default:
            return
        }
    }

    func photoAppeared(_ photo: Photo) async {
        guard case .loaded(let photos, .idle) = state,
            photos.suffix(Self.loadMoreThreshold).contains(where: { $0.id == photo.id })
        else { return }
        await run { await self.loadMore(after: photos) }
    }

    @discardableResult
    private func run<Result: Sendable>(
        _ operation: @escaping @MainActor @Sendable () async -> Result
    ) async -> Result {
        let task = Task { await operation() }
        cancelInFlight = { task.cancel() }
        return await task.value
    }

    private func loadMore(after photos: [Photo]) async {
        guard let loadMore else { return }
        let generation = generation
        state = .loaded(photos: photos, footer: .loading)
        do {
            let page = try await loadMore()
            guard generation == self.generation else { return }
            show(page)
        } catch {
            guard generation == self.generation else { return }
            state = .loaded(photos: photos, footer: .failed(LoadError(error)))
        }
    }

    private func showOfflineFeedOrFail(with error: LoadError) async {
        guard let saved = await loadOfflineFeed?(), !saved.isEmpty else {
            state = .failed(error)
            return
        }
        generation += 1
        loadMore = nil
        offlineReason = error
        state = .loaded(photos: saved, footer: .end)
    }

    private func showFirstPage(_ page: Paginated<Photo>) {
        generation += 1
        offlineReason = nil
        show(page)
    }

    private func show(_ page: Paginated<Photo>) {
        loadMore = page.loadMore
        state = .loaded(photos: page.items, footer: page.loadMore == nil ? .end : .idle)
    }

    private static let loadMoreThreshold = 6
}
