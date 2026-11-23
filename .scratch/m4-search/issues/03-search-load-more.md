# 03 — Load more Search results

Status: ready-for-agent
Blocked by: 02

`searchPhotoAppeared(_:)` forwards to the active search's `StreamPager`, which already holds the load-more rules (6-item threshold, one request in flight, failed footer, end). Expect each test to fail first only because the method does not exist yet; that compile failure is the red step.

## Files

- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryViewModel.swift`
- Edit: `Gallery/Tests/GalleryUITests/GalleryViewModelTests.swift`

## Shape

```swift
public func searchPhotoAppeared(_ photo: Photo) async {
    await activeSearch?.pager.photoAppeared(photo)
}
```

`retrySearch()` from ticket 02 already covers the failed footer, because `StreamPager.retry()` handles `.loaded(_, .failed)`.

## Acceptance

Each bullet is one `@Test`; use `loader.stubSearch(.success(loader.page(firstPage)))` and `loader.stubLoadMore(...)` (load-more stubs are shared with the feed, so each test stubs only what it uses):
- `searchPhotoAppeared_withinTheLastSixPhotosLoadsMoreAndAppends`: Photos 1…10, appear `[4]` → `loadMoreCallCount == 1`, `.loaded(firstPage + secondPage, .idle)`.
- `searchPhotoAppeared_beforeTheLastSixPhotosDoesNotLoadMore`: appear `[3]` → no load more.
- `searchPhotoAppeared_whileLoadingMoreShowsALoadingFooterAndDoesNotLoadAgain`: gate the load more; second appearance → `loadMoreCallCount == 1`, footer `.loading`.
- `searchPhotoAppeared_loadMoreFailureKeepsThePhotosAndShowsAFailedFooter`: `URLError(.notConnectedToInternet)` → `.loaded(firstPage, .failed(.offline))`.
- `retrySearch_afterALoadMoreFailureCallsTheSameLoadMoreAgain`: `searchQueries.count == 1`, `loadMoreCallCount == 2`, `.loaded(all, .end)`.
- `searchPhotoAppeared_atTheEndOfTheResultsRequestsNothing`: `hasMore: false`, appear last + `retrySearch()` → no calls.
- `searchPhotoAppeared_withoutASearchDoesNothing`: feed loaded with more, call `searchPhotoAppeared(feedPhotos[9])` → `loadMoreCallCount == 0`, `feed` unchanged.
- `photoAppeared_duringASearchLoadsMoreOfTheFeedOnly`: feed and search both loaded with more; `photoAppeared(feedPhotos[9])` → feed appended, `searchResults` unchanged.

## Decision log

Nothing new (rules are the feed's, see M2).

## Commit

`feat(ui): load more Search results` with a body noting the rules are shared with the feed through `StreamPager`.
