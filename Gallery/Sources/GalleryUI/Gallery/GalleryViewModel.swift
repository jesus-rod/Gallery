import GalleryCore
import Observation

@MainActor
@Observable
public final class GalleryViewModel {
    public typealias LoadFeed = @Sendable () async throws -> Paginated<Photo>

    public var feed: StreamState { feedPager.state }
    public private(set) var refreshError: LoadError?

    @ObservationIgnored private let feedPager: StreamPager

    public init(loadFeed: @escaping LoadFeed) {
        feedPager = StreamPager(loadFirstPage: loadFeed)
    }

    public func load() async {
        await feedPager.load()
    }

    public func dismissRefreshError() {
        refreshError = nil
    }

    public func refresh() async {
        refreshError = nil
        refreshError = await feedPager.refresh()
    }

    public func retry() async {
        await feedPager.retry()
    }

    public func photoAppeared(_ photo: Photo) async {
        await feedPager.photoAppeared(photo)
    }
}
