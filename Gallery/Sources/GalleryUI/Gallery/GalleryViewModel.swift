import Foundation
import GalleryCore
import Observation

@MainActor
@Observable
public final class GalleryViewModel {
    public typealias LoadFeed = @Sendable () async throws -> Paginated<Photo>
    public typealias LoadOfflineFeed = @Sendable () async -> [Photo]
    public typealias Search = @Sendable (String) async throws -> Paginated<Photo>

    public var feed: StreamState { feedPager.state }
    public var offlineFeedReason: LoadError? { feedPager.offlineReason }
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

    public init(
        loadFeed: @escaping LoadFeed,
        loadOfflineFeed: @escaping LoadOfflineFeed,
        search: @escaping Search
    ) {
        feedPager = StreamPager(loadFirstPage: loadFeed, loadOfflineFeed: loadOfflineFeed)
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

    public func refreshSearch() async {
        guard let pager = activeSearch?.pager else { return }
        refreshError = nil
        let error = await pager.refresh()
        guard pager === activeSearch?.pager else { return }
        refreshError = error
    }

    public func retry() async {
        await feedPager.retry()
    }

    public func photoAppeared(_ photo: Photo) async {
        await feedPager.photoAppeared(photo)
    }

    public func search(_ query: String) async {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, query != activeSearch?.query || shownSearchFailed else { return }
        activeSearch?.pager.cancel()
        let searchPhotos = searchPhotos
        let pager = StreamPager(loadFirstPage: { try await searchPhotos(query) })
        activeSearch = ActiveSearch(query: query, pager: pager)
        await pager.load()
    }

    private var shownSearchFailed: Bool {
        if case .failed? = activeSearch?.pager.state { true } else { false }
    }

    public func retrySearch() async {
        await activeSearch?.pager.retry()
    }

    public func searchPhotoAppeared(_ photo: Photo) async {
        await activeSearch?.pager.photoAppeared(photo)
    }

    public static let feedStreamID = "feed"

    public static func searchStreamID(for query: String) -> String {
        "search-\(query)"
    }

    public func photos(in streamID: String) -> [Photo] {
        guard let pager = pager(for: streamID), case .loaded(let photos, _) = pager.state else { return [] }
        return photos
    }

    public func photoAppeared(_ photo: Photo, in streamID: String) async {
        await pager(for: streamID)?.photoAppeared(photo)
    }

    private func pager(for streamID: String) -> StreamPager? {
        if streamID == Self.feedStreamID { return feedPager }
        guard let activeSearch, streamID == Self.searchStreamID(for: activeSearch.query) else { return nil }
        return activeSearch.pager
    }

    public func cancelSearch() {
        activeSearch?.pager.cancel()
        activeSearch = nil
    }
}
