import Foundation
import GalleryCore
import Observation

@MainActor
@Observable
public final class GalleryViewModel {
    public typealias LoadFeed = @Sendable () async throws -> Paginated<Photo>
    public typealias Search = @Sendable (String) async throws -> Paginated<Photo>

    public var feed: StreamState { feedPager.state }
    public private(set) var refreshError: LoadError?

    public var searchResults: SearchResults? {
        activeSearch.map { SearchResults(query: $0.query, state: $0.pager.state) }
    }

    @ObservationIgnored private let feedPager: StreamPager
    @ObservationIgnored private let searchPhotos: Search
    private var activeSearch: ActiveSearch?

    private struct ActiveSearch {
        let query: String
        let pager: StreamPager
    }

    public init(loadFeed: @escaping LoadFeed, search: @escaping Search) {
        feedPager = StreamPager(loadFirstPage: loadFeed)
        searchPhotos = search
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

    public func search(_ query: String) async {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, query != activeSearch?.query else { return }
        activeSearch?.pager.cancel()
        let searchPhotos = searchPhotos
        let pager = StreamPager(loadFirstPage: { try await searchPhotos(query) })
        activeSearch = ActiveSearch(query: query, pager: pager)
        await pager.load()
    }

    public func retrySearch() async {
        await activeSearch?.pager.retry()
    }

    public func searchPhotoAppeared(_ photo: Photo) async {
        await activeSearch?.pager.photoAppeared(photo)
    }

    public func cancelSearch() {
        activeSearch?.pager.cancel()
        activeSearch = nil
    }
}
