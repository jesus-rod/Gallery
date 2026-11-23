import GalleryCore
import Observation

@MainActor
@Observable
public final class GalleryViewModel {
    public typealias LoadFeed = @Sendable () async throws -> Paginated<Photo>

    public private(set) var feed: StreamState = .loading

    @ObservationIgnored private let loadFeed: LoadFeed

    public init(loadFeed: @escaping LoadFeed) {
        self.loadFeed = loadFeed
    }

    public func retry() async {
        feed = .loading
        await load()
    }

    public func load() async {
        do {
            let page = try await loadFeed()
            feed = .loaded(photos: page.items, footer: page.loadMore == nil ? .end : .idle)
        } catch {
            feed = .failed(LoadError(error))
        }
    }
}
