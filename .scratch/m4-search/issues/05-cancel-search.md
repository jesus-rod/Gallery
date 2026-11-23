# 05 — Cancel search restores the Editorial feed

Status: done
Blocked by: 04

`cancelSearch()` drops the active search and cancels its in-flight first-page load. The feed is untouched, so the view shows it again with no request.

## Files

- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryViewModel.swift`
- Edit: `Gallery/Tests/GalleryUITests/GalleryViewModelTests.swift`
- Edit: `docs/decision-log.md`

## Shape

```swift
public func cancelSearch() {
    searchTask?.cancel()
    searchTask = nil
    activeSearch = nil
}
```

## Acceptance

Each bullet is one `@Test`:
- `cancelSearch_showsTheFeedAgainWithoutRequestingIt`: `load()`, `search("cats")`, `cancelSearch()` → `searchResults == nil`, `feed` equals the loaded feed, `loadFeedCallCount == 1`.
- `cancelSearch_cancelsTheInFlightSearchAndDiscardsItsResult`: gate "cats"; in a `Task` call `search("cats")`; `untilReached`; `cancelSearch()`; open; await → `cancelledSearchQueries == ["cats"]`, `searchResults == nil`.
- `cancelSearch_keepsTheFeedLoadMoreRunning`: feed loaded with more; gate a feed load more from `photoAppeared(feed[9])` in a `Task`; `search("cats")`; `cancelSearch()`; open; await → feed shows the appended Photos.
- `search_afterCancelSearchRequestsTheSameQueryAgain`: `search("cats")`, `cancelSearch()`, `search("cats")` → `searchQueries == ["cats", "cats"]`.
- `cancelSearch_withoutASearchDoesNothing`: `searchResults == nil`, no loader calls.

## Decision log

- Cancelling search only drops the search pager; the feed's pager, Photos and in-flight load more are untouched, so going back costs no request.

## Commit

`feat(ui): cancel search and return to the Editorial feed`.

## Comments

- The five tests were written together before the code. The red step was a compile failure on the missing `cancelSearch()`, which the ticket accepts.
