import GalleryCore
import Observation

@MainActor
@Observable
public final class GalleryViewModel {
    public typealias LoadFeed = @Sendable () async throws -> Paginated<Photo>

    public private(set) var feed: StreamState = .loading

    @ObservationIgnored private let loadFeed: LoadFeed
    @ObservationIgnored private var loadMore: Paginated<Photo>.LoadMore?

    public init(loadFeed: @escaping LoadFeed) {
        self.loadFeed = loadFeed
    }

    public func load() async {
        do {
            show(try await loadFeed())
        } catch {
            feed = .failed(LoadError(error))
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
        feed = .loaded(photos: photos, footer: .loading)
        do {
            show(try await loadMore())
        } catch {
            feed = .loaded(photos: photos, footer: .failed(LoadError(error)))
        }
    }

    private func show(_ page: Paginated<Photo>) {
        loadMore = page.loadMore
        feed = .loaded(photos: page.items, footer: page.loadMore == nil ? .end : .idle)
    }

    private static let loadMoreThreshold = 6
}
