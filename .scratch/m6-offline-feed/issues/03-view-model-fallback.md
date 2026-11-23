# 03 — View model: fall back to the Offline feed

Status: done
Blocked by: none (UI only; uses closures, not Core's store)

## Files

- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryViewModel.swift` (and `StreamPager.swift` if the fallback lives there)
- Edit: `Gallery/Tests/GalleryUITests/GalleryViewModelTests.swift`, `Helpers/FeedLoaderSpy.swift` as needed
- Edit: every `GalleryViewModel(` call site (previews, `App/GalleryApp.swift`: pass `loadOfflineFeed: { [] }` for now; ticket 05 wires the store)
- Edit: `docs/decision-log.md`

## Shape

See spec "Shape" and "Fallback rule". New init parameter `loadOfflineFeed` between `loadFeed` and `search`; new `offlineFeedReason: LoadError?`.

## Tests (one at a time, through `GalleryViewModel` only)

1. `load()` succeeding never calls `loadOfflineFeed` and leaves `offlineFeedReason` nil.
2. `load()` failing with `URLError(.notConnectedToInternet)` and a non-empty Offline feed → `feed == .loaded(photos: saved, footer: .end)`, `offlineFeedReason == .offline`.
3. Same with `UnsplashAPIError.rateLimited` → `offlineFeedReason == .rateLimited`.
4. `load()` failing with an empty Offline feed → `feed == .failed(.offline)`, reason nil.
5. `retry()` after (4) applies the same fallback when the store now has Photos.
6. `refresh()` while the Offline feed is shown, succeeding → live Photos, reason nil, `refreshError` nil.
7. `refresh()` while the Offline feed is shown, failing → saved Photos kept, reason unchanged, `refreshError == .offline`; `loadOfflineFeed` not called again.
8. `photoAppeared` on the last saved Photo requests nothing (no load more).
9. Search while the Offline feed is shown leaves feed and reason untouched; `cancelSearch()` returns to it.

## Decision log

- The view model falls back to the Offline feed on any first-Page error, not only offline, because a rate-limited or failing API also leaves nothing to show; `offlineFeedReason` keeps the error so the banner can say why.
- The Offline feed has no load more: paging needs the network, and the saved Photos are a prefix of the feed.

## Commit

`feat(ui): show the Offline feed when the first Page fails`
