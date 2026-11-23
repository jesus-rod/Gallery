# M2 — Grid UI with fixtures

Status: in progress

## Goal

The app launches into an endless grid of the Editorial feed, driven by an `@Observable` `@MainActor` `GalleryViewModel` over `PhotoStream`. With `-useStubs` it runs entirely on bundled JSON fixtures, and an XCUITest target proves the grid end to end.

## Use cases

**Load the Editorial feed**
- Happy: launch → loading state (skeleton) → first Page of Photos in the grid.
- Sad: first Page fails → full-screen error with retry. `UnsplashAPIError.rateLimited` → rate-limited state; `URLError` connectivity codes → offline; anything else → generic. No Foundation or API error reaches a view.

**Load more**
- Happy: a Photo about 6 items before the end appears → `loadMore` runs, the footer shows a spinner, new Photos append.
- One request in flight: further appearances while loading do nothing.
- Sad: `loadMore` fails → inline retry footer with the mapped error; retry calls the same `loadMore` again.
- End: `loadMore` is nil → no footer, nothing more requested.

**Refresh** (pull to refresh)
- Happy: reloads the first Page and replaces the Photos.
- Sad: keeps the current Photos and exposes the mapped error.

**Caption**
- Alt description → description → localized "Untitled photo". Used as each cell's VoiceOver label.

**Run on fixtures**
- `-useStubs` swaps the API client for a `StubHTTPClient` answering Editorial page requests from bundled JSON. No access key needed.

## Seams under test

| Seam | Observed through |
|---|---|
| `caption(for: Photo)` | Return value |
| `GalleryViewModel(loadFeed: () async throws -> Paginated<Photo>)` | `feed` state after `load()`, `photoAppeared(_:)`, `retry()`, `refresh()`, given a stubbed loader |
| `GalleryViewModel` lifetime | Deallocated after the test (weak reference), no retain cycle through `loadMore` |
| `StubHTTPClient` | Response for an Editorial request (page N → fixture N, beyond → empty array) |
| App end to end | XCUITest with `-useStubs`: grid shows fixture Photos; scrolling loads page 2 |

Views (`PhotoGrid`, cell, footer, error and skeleton views) stay logic-free and are covered by the XCUITests and `#Preview`s.

## Shape (proposed)

```swift
@Observable @MainActor public final class GalleryViewModel {
    public private(set) var feed: StreamState
    public func load() async
    public func photoAppeared(_ photo: Photo) async
    public func retry() async
    public func refresh() async
}

public enum StreamState {
    case loading
    case failed(LoadError)
    case loaded(photos: [Photo], footer: Footer)
}
public enum Footer { case idle, loading, failed(LoadError), end }
public enum LoadError { case offline, rateLimited, generic }
```

`StreamState` is per Stream so M4 adds a second one for Search results without touching the feed's.

## Out of scope

Image loading and Previews (M3: cells show a neutral fill), search (M4), full-screen view (M5), offline feed (M6), visual polish and snapshot tests (M7).

## Pattern notes

The view model takes a closure, not `PhotoStream`, so tests stub paging directly (essential-feed: depend on the narrowest abstraction). Memory-leak checks use a `weak` reference asserted at the end of each test, Swift Testing having no `addTeardownBlock`.
