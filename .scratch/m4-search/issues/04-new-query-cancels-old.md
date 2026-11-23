# 04 — A new Query cancels the old one

Status: ready-for-agent
Blocked by: 03

When a Query is submitted while the previous Query's first Page is still loading, the old request is cancelled and its late result never shows. Discarding already works because the old `StreamPager` is no longer referenced (ticket 02); this ticket adds real cancellation by running the first-page load in a stored `Task`.

Write `search_newQueryCancelsTheInFlightSearch` first: it is the red test. The two "discards" tests pin behaviour that already holds and may pass at once; keep them as regression tests.

## Files

- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryViewModel.swift`
- Edit: `Gallery/Tests/GalleryUITests/Helpers/FeedLoaderSpy.swift`
- Edit: `Gallery/Tests/GalleryUITests/GalleryViewModelTests.swift`
- Edit: `docs/decision-log.md`

## Shape

`GalleryViewModel`:

```swift
@ObservationIgnored private var searchTask: Task<Void, Never>?

public func search(_ query: String) async {
    let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty, query != activeSearch?.query else { return }
    searchTask?.cancel()
    let searchPhotos = searchPhotos
    let pager = StreamPager(loadFirstPage: { try await searchPhotos(query) })
    activeSearch = ActiveSearch(query: query, pager: pager)
    let task = Task { await pager.load() }
    searchTask = task
    await task.value
}
```

The task captures only `pager`, never `self`, so there is no retain cycle.

`FeedLoaderSpy.search(_:)` records cancellation after the gate:

```swift
private(set) var cancelledSearchQueries: [String] = []

func search(_ query: String) async throws -> Paginated<Photo> {
    searchQueries.append(query)
    let stub = next(from: &searchStubs, named: "search")
    await stub.gate?.pass()
    if Task.isCancelled { cancelledSearchQueries.append(query) }
    return try stub.result.get()
}
```

## Acceptance

Each bullet is one `@Test`. Pattern: `let gate = Gate()`, stub "cats" with the gate, stub "dogs" without; `let first = Task { await sut.search("cats") }`; `await gate.untilReached()`; `await sut.search("dogs")`; `gate.open()`; `await first.value`.
- `search_newQueryCancelsTheInFlightSearch`: `cancelledSearchQueries == ["cats"]`, `searchQueries == ["cats", "dogs"]`.
- `search_newQueryDiscardsTheLateFirstPageOfThePreviousQuery`: `searchResults == SearchResults(query: "dogs", state: .loaded(photos: dogs, footer: .end))`.
- `search_newQueryDiscardsALateLoadMoreOfThePreviousQuery`: "cats" loaded with more; gate a load more started by `searchPhotoAppeared(cats[9])` in a `Task`; `search("dogs")`; open the gate → `searchResults` still shows "dogs" only.
- `search_sameQueryWhileItLoadsDoesNotCancelIt`: while "cats" is gated, `search("cats")` again → `cancelledSearchQueries` empty, `searchQueries == ["cats"]`.

## Decision log

- A new Query cancels the previous search's `Task` (the cancellation reaches `URLSession` through `PhotoStream`), and a late result can never show because it lands on the previous Query's pager, which nothing references any more.

## Commit

`feat(ui): cancel the previous Query when a new one is submitted`.
