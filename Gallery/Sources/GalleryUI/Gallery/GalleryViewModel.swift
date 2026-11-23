import GalleryCore
import Observation

@MainActor
@Observable
public final class GalleryViewModel {
    public typealias LoadFeed = @Sendable () async throws -> Paginated<Photo>

    public private(set) var feed: StreamState = .loading
    public private(set) var refreshError: LoadError?

    @ObservationIgnored private let loadFeed: LoadFeed
    @ObservationIgnored private var loadMore: Paginated<Photo>.LoadMore?
    @ObservationIgnored private var generation = 0

    public init(loadFeed: @escaping LoadFeed) {
        self.loadFeed = loadFeed
    }

    public func load() async {
        do {
            showFirstPage(try await loadFeed())
        } catch {
            feed = .failed(LoadError(error))
        }
    }

    public func dismissRefreshError() {
        refreshError = nil
    }

    public func refresh() async {
        refreshError = nil
        do {
            showFirstPage(try await loadFeed())
        } catch {
            refreshError = LoadError(error)
        }
    }

    public func retry() async {
        switch feed {
        case .failed:
            feed = .loading
            await load()
        case .loaded(let photos, .failed):
            await loadMore(after: photos)
        default:
            return
        }
    }

    public func photoAppeared(_ photo: Photo) async {
        guard case .loaded(let photos, .idle) = feed,
            photos.suffix(Self.loadMoreThreshold).contains(where: { $0.id == photo.id })
        else { return }
        await loadMore(after: photos)
    }

    private func loadMore(after photos: [Photo]) async {
        guard let loadMore else { return }
        let generation = generation
        feed = .loaded(photos: photos, footer: .loading)
        do {
            let page = try await loadMore()
            guard generation == self.generation else { return }
            show(page)
        } catch {
            guard generation == self.generation else { return }
            feed = .loaded(photos: photos, footer: .failed(LoadError(error)))
        }
    }

    private func showFirstPage(_ page: Paginated<Photo>) {
        generation += 1
        show(page)
    }

    private func show(_ page: Paginated<Photo>) {
        loadMore = page.loadMore
        feed = .loaded(photos: page.items, footer: page.loadMore == nil ? .end : .idle)
    }

    private static let loadMoreThreshold = 6
}
