# M4 — Search

Status: done

## Goal

A search field above the grid. Submitting a Query (ADR 0003: on submit, never as you type) shows its Search results in the same `PhotoGrid`, with the same `PhotoImages`, so cached Renditions are shared. Cancelling the search brings back the Editorial feed instantly: no request, same scroll position. `-useStubs` answers search requests from bundled fixtures, so the XCUITests stay offline.

## Use cases

**Submit a Query**
- Happy: type "cats", submit → skeleton → first Page of Search results in the grid, replacing the Editorial feed.
- The Query is trimmed (whitespace and newlines). An empty or whitespace-only Query does nothing: no request, no state change.
- Submitting the Query that is already shown (after trimming) does nothing, which saves the Request budget.
- Sad: first Page fails → full-screen error with retry; `rateLimited` → the rate-limited state; same `LoadError` mapping as the feed.
- Empty: zero Photos → "No photos for “cats”" with the Query echoed.

**Load more Search results**
- Same rules as the feed: a Photo within the last 6 appears → footer spinner → appended Photos. One request in flight. Failure → inline retry footer, Photos kept. End: `PhotoStream` stops at `totalPages` or an empty Page, so the footer is `end` and nothing more is requested.

**New Query while one is loading**
- Submitting "dogs" while "cats" is still loading cancels the "cats" request. A "cats" result (first Page or load more) that arrives late is discarded.

**Cancel search**
- Tapping Cancel, or clearing the field, shows the Editorial feed again: no request, same Photos, same scroll position (its view stays alive while hidden). Any in-flight search is cancelled and its result discarded.
- The feed is never touched by a search: its Photos, footer and in-flight load more carry on.

**Run on fixtures**
- With `-useStubs`, `GET /search/photos?query=cats&page=N` answers from `search-cats-page-N.json`; any other Query or page answers zero results.

## Seams under test

| Seam | Observed through |
|---|---|
| `GalleryViewModel(loadFeed:search:)` | `searchResults` after `search(_:)`, `searchPhotoAppeared(_:)`, `retrySearch()`, `cancelSearch()`, given stubbed closures (`FeedLoaderSpy`) |
| Same, feed isolation | `feed` and `loadFeedCallCount` unchanged by any search call |
| Same, cancellation | `FeedLoaderSpy.cancelledSearchQueries` (the search closure saw `Task.isCancelled`); late results never reach `searchResults` |
| `GalleryViewModel` lifetime | Deallocated after every test (`.trackingLeaks`) |
| `StubHTTPClient` search routing | XCUITests (the app target has no unit test target, same as M2/07) |
| App end to end | XCUITest with `-useStubs`: submit "cats" → results; Cancel → feed back; "zzzz" → empty state |

Views (`GalleryRootView` switching, `EmptySearchView`) stay logic-free and are covered by the XCUITests and `#Preview`s. Snapshot tests are M7.

## Shape

One design: **both Streams are instances of one internal paging state machine, `StreamPager`**, extracted from today's `GalleryViewModel`. The feed has one pager for the app's lifetime; each submitted Query gets a brand-new pager. A late result from an old Query lands on a pager nobody references any more, so discarding it needs no generation bookkeeping, and the feed's pager is never touched by search. Explicit `search…` methods (rather than a Stream parameter) keep the existing feed API and tests unchanged.

```swift
@MainActor @Observable
final class StreamPager {                                // internal, GalleryUI/Gallery/StreamPager.swift
    typealias LoadFirstPage = @Sendable () async throws -> Paginated<Photo>
    private(set) var state: StreamState = .loading
    init(loadFirstPage: @escaping LoadFirstPage)
    func load() async
    func refresh() async -> LoadError?                   // nil on success
    func retry() async
    func photoAppeared(_ photo: Photo) async
}

public struct SearchResults: Equatable, Sendable {       // GalleryUI/Gallery/SearchResults.swift
    public let query: String
    public let state: StreamState
    public init(query: String, state: StreamState)
}

@MainActor @Observable
public final class GalleryViewModel {
    public typealias LoadFeed = @Sendable () async throws -> Paginated<Photo>
    public typealias Search = @Sendable (String) async throws -> Paginated<Photo>

    public var feed: StreamState { get }                 // feedPager.state
    public private(set) var refreshError: LoadError?
    public var searchResults: SearchResults? { get }     // nil → the feed is shown

    public init(loadFeed: @escaping LoadFeed, search: @escaping Search)

    public func load() async
    public func refresh() async
    public func retry() async
    public func photoAppeared(_ photo: Photo) async
    public func dismissRefreshError()

    public func search(_ query: String) async
    public func searchPhotoAppeared(_ photo: Photo) async
    public func retrySearch() async
    public func cancelSearch()
}
```

`StreamState` is reused unchanged for Search results. Empty results are `.loaded(photos: [], footer: .end)`; the view shows `EmptySearchView(query:)` for that case. "Which Stream is shown" is `searchResults == nil` (feed) or not (search); the view model exposes nothing else.

`search(_:)` keeps the running first-page load in `searchTask: Task<Void, Never>?`; a new Query or `cancelSearch()` calls `searchTask?.cancel()`, which cancels the request through `PhotoStream` and `URLSession`.

Composition root: a second `PhotoStream` per Query, `UnsplashEndpoint.search(query:page:)` → API client → `SearchPhotosMapper`, passed as `search: { query in try await searchStream(query).firstPage() }`.

`GalleryRootView`: `.searchable(text:placement: .navigationBarDrawer(displayMode: .always))`, `.onSubmit(of: .search)` calls `search(_:)`, an empty field calls `cancelSearch()`. The feed content stays in a `ZStack` under the search content, hidden with `opacity(0)`, `allowsHitTesting(false)` and `accessibilityHidden(true)`, so its `ScrollView` keeps its scroll position. The search grid gets `.id(query)` so each Query starts at the top.

## Tickets (in order)

01 extract `StreamPager` (refactor) · 02 search first Page, errors, empty, trimming, plus composition root wiring (the `init` change forces it) · 03 load more Search results · 04 a new Query cancels the old one · 05 cancel search restores the feed · 06 search fixtures for `-useStubs` · 07 search UI · 08 XCUITests · 09 review, docs, roadmap.

## Out of scope

Search as you type (ADR 0003), pull to refresh on Search results, search history or suggestions, storing Search results offline (M6), Full-screen view (M5), snapshot tests (M7).

## Carried items

- From M3: ticket M3/12 (live run with a real key) is still open and needs the user. Ticket 09 asks the user to run search live in the same session (one search costs one request per Page).
- Load more uses `.onAppear { Task {} }`; image loads use `.task(id:)`. The search grid is the same `PhotoGrid`, so this carries over unchanged.
- `PhotoGrid` and `PhotoImages` are shared by both Streams: the root view passes the same `images` to both grids.
- `-useStubs` covered only the Editorial feed: ticket 06 adds search fixtures and routing.
- Mapper helper ("rate limit, require 200, decode or `invalidData`"): no third mapper in M4, still not extracted.
- EF-97 vs swift-format: the linter wins (`case .loaded(let photos, let footer)`).
- Carried to M7, untouched here: synchronous memory-cache lookup to skip the Preview fade; snapshot tests.
- Lint all three folders: `swift format lint -r Gallery App AppUITests`.

## Pattern notes

The view model still depends on closures, not on `PhotoStream` (narrowest dependency). `StreamPager` is the extract-class refactor that lets two Streams share one tested state machine; it is internal and tested only through `GalleryViewModel`, so the seam stays the public API. Cancellation is checked through the spy, not by timing.

## Rules for the implementer

- TDD per ticket: one failing test (Swift Testing: `@Test`, `#expect`, `@Suite(.trackingLeaks)`), minimal code to green, repeat. Every SUT goes through `makeSUT`, which calls `trackForMemoryLeaks`. XCUITest only for app end to end.
- Commands: `cd Gallery && swift test`; from the repo root `swift format lint -r Gallery App AppUITests` (fix with `swift format -i -r Gallery App AppUITests`). App build: `xcodebuild build -project Gallery.xcodeproj -scheme GalleryApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`. UI tests: `xcodebuild test -project Gallery.xcodeproj -scheme GalleryApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GalleryAppUITests`.
- No code comments anywhere. Swift 6 strict concurrency, `@Observable @MainActor` view model, iOS 17 minimum.
- `App/` and `AppUITests/` are synchronized folder groups: new files there need no `project.pbxproj` edits, and files in `App/Stubs/Fixtures/` are bundled automatically.
- Each notable decision goes into `docs/decision-log.md` under a `## M4 — Search` heading (create it in ticket 01), in the same commit as the code. Each ticket lists its log lines.
- One commit per ticket, conventional style like the existing log (`refactor(ui): ...`, `feat(ui): ...`, `feat(app): ...`, `test(app): ...`, `docs(scratch): ...`) with a 2–4 line body. Set the ticket's `Status: done` in that commit. Commits are authored by the user with plain `git commit`; never add a `Co-Authored-By` or any Claude attribution line. Propose the commit message and wait for the user's approval before committing.

## Review notes

Quick essential-feed pass over the M4 diff (`540efd8~1..HEAD`) at the end of M4.
- The view model depends only on the `loadFeed` and `search` closures. `PhotoStream`, endpoints and mappers appear only in the composition root (`App/GalleryApp.swift`), and no Foundation or API error reaches a view: `LoadError` maps them, and the views do not import Foundation. The view model imports Foundation only to trim the Query.
- `StreamPager` is internal and tested only through `GalleryViewModel`. Every view model SUT goes through `makeSUT`, which calls `trackForMemoryLeaks`. Swift sources have no code comments.
- Known edge: search never cancels the feed, so the feed's in-flight load more can still land while Search results are shown. It only appends to the hidden feed pager, so nothing visible changes.
- Known edge: the feed's refresh banner is an overlay on the feed, so it is hidden while Search results show, and Search results have no pull to refresh (out of scope).
- Known edge: a 401 for a search shows the generic error, as the feed does (see M3/12).
