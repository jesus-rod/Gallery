# 02 — Pull to refresh on Search results

Status: done
Blocked by: none

## Files

- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryViewModel.swift`
- Edit: `Gallery/Tests/GalleryUITests/GalleryViewModelTests.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryRootView.swift` (`.refreshable` on the search grid; show `RefreshErrorBanner` whether or not search is shown)
- Edit: `docs/decision-log.md`

## Shape

`public func refreshSearch() async`: re-runs the active Query's first Page through its `StreamPager.refresh()`; on failure keeps the shown results and sets the same `refreshError` the feed uses. No-op without an active search.

## Tests (one at a time)

1. `refreshSearch()` with an active Query requests that Query again and shows the new Photos.
2. Failure keeps the previous results and sets `refreshError` (e.g. `.offline`).
3. Without an active search it requests nothing.
4. A refresh whose Query was replaced meanwhile (new `search`) doesn't overwrite the new results (cancelled with the old pager).

## Decision log

- Search results get pull to refresh, sharing the feed's brief refresh error, which now shows over Search results too.
- The hidden feed may still finish an in-flight load more while searching: accepted, it costs at most one request the user already triggered.

## Commit

`feat(ui): pull to refresh Search results`
