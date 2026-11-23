# 02 — Search: first Page, errors, empty, trimming

Status: ready-for-agent
Blocked by: 01

`GalleryViewModel` gains a `search` closure and the first half of the search API: `search(_:)`, `retrySearch()` and the `searchResults` state. Each accepted Query gets a new `StreamPager`. Because `init` changes, this ticket also updates the two other callers: the `#Preview` helper and the composition root, which wires the real search Stream.

## Files

- New: `Gallery/Sources/GalleryUI/Gallery/SearchResults.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryViewModel.swift`
- Edit: `Gallery/Tests/GalleryUITests/Helpers/FeedLoaderSpy.swift`
- Edit: `Gallery/Tests/GalleryUITests/GalleryViewModelTests.swift` (new tests after the feed tests, no comments or MARKs; `makeSUT` passes `search: loader.search`)
- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryPreviews.swift`
- Edit: `App/GalleryApp.swift`
- Edit: `docs/decision-log.md`

## Shape

```swift
public struct SearchResults: Equatable, Sendable {
    public let query: String
    public let state: StreamState
    public init(query: String, state: StreamState)
}
```

In `GalleryViewModel` (add `import Foundation` for trimming):

```swift
public typealias Search = @Sendable (String) async throws -> Paginated<Photo>

public var searchResults: SearchResults? {
    activeSearch.map { SearchResults(query: $0.query, state: $0.pager.state) }
}

@ObservationIgnored private let searchPhotos: Search
private var activeSearch: ActiveSearch?

private struct ActiveSearch {
    let query: String
    let pager: StreamPager
}

public init(loadFeed: @escaping LoadFeed, search: @escaping Search)

public func search(_ query: String) async {
    let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty, query != activeSearch?.query else { return }
    let searchPhotos = searchPhotos
    let pager = StreamPager(loadFirstPage: { try await searchPhotos(query) })
    activeSearch = ActiveSearch(query: query, pager: pager)
    await pager.load()
}

public func retrySearch() async {
    await activeSearch?.pager.retry()
}
```

`activeSearch` is observed (not `@ObservationIgnored`) because it is replaced per Query.

`FeedLoaderSpy` additions:

```swift
private(set) var searchQueries: [String] = []
private var searchStubs: [Stub] = []

func stubSearch(_ result: Result<Paginated<Photo>, Error>, gate: Gate? = nil)

func search(_ query: String) async throws -> Paginated<Photo> {
    searchQueries.append(query)
    return try await resolve(next(from: &searchStubs, named: "search"))
}
```

`GalleryPreviews.swift`: `PreviewData.viewModel(_:)` becomes `GalleryViewModel(loadFeed: load, search: { _ in Paginated(items: PreviewData.photos(31...42)) })`.

`App/GalleryApp.swift`, `CompositionRoot.makeGalleryViewModel()`: rename the existing stream to `feedStream` and pass

```swift
search: { query in
    let searchStream = PhotoStream { page in
        let request = UnsplashEndpoint.search(query: query, page: page).request(baseURL: baseURL)
        let (data, response) = try await client.send(request)
        return try SearchPhotosMapper.map(data, from: response)
    }
    return try await searchStream.firstPage()
}
```

## Acceptance

Each bullet is one `@Test` in `GalleryViewModelTests`:
- `init_hasNoSearchResults`: `searchResults == nil`, `searchQueries` empty.
- `search_requestsTheFirstPageForTheTrimmedQuery`: `search("  cats \n")` → `searchQueries == ["cats"]`.
- `search_withAnEmptyOrWhitespaceQueryDoesNothing(query:)`, arguments `["", "   ", " \n\t "]`: no call, `searchResults == nil`.
- `search_showsLoadingWithTheQueryWhileTheFirstPageLoads`: gate the stub; while held, `searchResults == SearchResults(query: "cats", state: .loading)`.
- `search_deliversTheFirstPageWithAnIdleFooterWhenMoreCanLoad`: `.loaded(photos:, footer: .idle)`.
- `search_deliversTheFirstPageWithAnEndFooterWhenNothingMoreCanLoad`: `.loaded(photos:, footer: .end)`.
- `search_deliversNoPhotosAsLoadedWithAnEndFooter`: stub `page([], hasMore: false)` → `SearchResults(query: "cats", state: .loaded(photos: [], footer: .end))`.
- `search_failsWithTheMappedError(error:expected:)`, arguments `rateLimited → .rateLimited`, `URLError(.notConnectedToInternet) → .offline`, `AnyError() → .generic`.
- `search_withTheQueryAlreadyShownDoesNotRequestAgain`: `search("cats")` then `search(" cats ")` → `searchQueries == ["cats"]`.
- `search_doesNotChangeTheFeed`: after `load()` then `search("cats")`, `feed` equals the loaded feed and `loadFeedCallCount == 1`.
- `retrySearch_afterAFailedFirstPageRequestsTheSameQueryAgain`: fail then succeed → `searchQueries == ["cats", "cats"]`, state `.loaded`.
- `retrySearch_withoutASearchDoesNothing`: no search call, `searchResults == nil`.
- All earlier tests still pass; leak checks pass; app builds with `xcodebuild build …`.

## Decision log

- The view model takes a `search: (String) async throws -> Paginated<Photo>` closure next to `loadFeed`; the composition root builds a new `PhotoStream` with `SearchPhotosMapper` per Query.
- Each Query gets its own `StreamPager`; Search results reuse `StreamState`, and empty results are `.loaded(photos: [], footer: .end)`.
- The Query is trimmed; an empty Query, or the Query already shown, sends no request (Request budget).

## Commit

`feat(ui): search the first Page of a Query` with a body covering the closure, trimming and the same-Query rule.
