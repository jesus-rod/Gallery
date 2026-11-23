import GalleryCore
import Observation

@MainActor
@Observable
final class StreamPager {
    typealias LoadFirstPage = @Sendable () async throws -> Paginated<Photo>

    private(set) var state: StreamState = .loading

    @ObservationIgnored private let loadFirstPage: LoadFirstPage
    @ObservationIgnored private var loadMore: Paginated<Photo>.LoadMore?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var inFlight: Task<Void, Never>?

    init(loadFirstPage: @escaping LoadFirstPage) {
        self.loadFirstPage = loadFirstPage
    }

    func load() async {
        await run {
            do {
                self.showFirstPage(try await self.loadFirstPage())
            } catch {
                self.state = .failed(LoadError(error))
            }
        }
    }

    func cancel() {
        inFlight?.cancel()
        inFlight = nil
        generation += 1
    }

    func refresh() async -> LoadError? {
        do {
            showFirstPage(try await loadFirstPage())
            return nil
        } catch {
            return LoadError(error)
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

    private func run(_ operation: @escaping @MainActor @Sendable () async -> Void) async {
        let task = Task { await operation() }
        inFlight = task
        await task.value
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

    private func showFirstPage(_ page: Paginated<Photo>) {
        generation += 1
        show(page)
    }

    private func show(_ page: Paginated<Photo>) {
        loadMore = page.loadMore
        state = .loaded(photos: page.items, footer: page.loadMore == nil ? .end : .idle)
    }

    private static let loadMoreThreshold = 6
}
