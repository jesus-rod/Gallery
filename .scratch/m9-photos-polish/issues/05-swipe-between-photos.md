# 05 — Swipe between photos with parallax

Status: ready-for-agent
Blocked by: 03, 04

The biggest ticket: full screen pages through the Stream the photo came from. Write ADR 0007 first.

## Shape

- `FullScreenRoute` names the Stream (`streamID`) and the starting Photo id, plus the grid size. The destination view reads that Stream's Photos from the view model (`viewModel.photos(in: streamID)`), so new Pages appear while paging.
- New `FullScreenPager` view: horizontal `ScrollView` + `LazyHStack` of pages, `.scrollTargetBehavior(.paging)`, `.scrollPosition(id: $currentID)`, `.scrollDisabled(isCurrentPageZoomed)`. Each page is today's zoomable photo content (extract it from `FullScreenPhotoView` into `ZoomablePhotoPage`), so zoom state is per page and resets when the page leaves.
- Parallax: inside each page, the image gets `.visualEffect { content, proxy in content.offset(x: Parallax.offset(pageMinX: proxy.frame(in: .scrollView).minX, pageWidth: proxy.size.width, factor: Design.Motion.parallaxFactor)) }`. No state writes per frame.
- Ambient backdrop and chrome follow `currentID` (cross-fade the backdrop on change).
- Load more: when `currentID` is within the load-more distance of the end, call the same `photoAppeared` / `searchPhotoAppeared` the grid calls.
- Memory: only pages within ±1 of the current one request the full-screen Rendition (`.task(id:)` cancels as pages leave); others show the grid image from the memory cache.
- Dismiss: `currentID` writes back to the root (binding or callback); the zoom transition source id becomes `"\(streamID)-\(currentID)"`, and the grid's `.scrollPosition(id:)` moves to that cell before the pop so the zoom returns to a visible cell.

## Files

- New: `docs/adr/0007-full-screen-pages-through-the-stream.md`
- New: `FullScreen/FullScreenPager.swift`, `FullScreen/ZoomablePhotoPage.swift`, `FullScreen/Parallax.swift`
- Edit: `FullScreen/FullScreenRoute.swift`, `FullScreen/FullScreenPhotoView.swift` (becomes the pager's host: backdrop, chrome, sheet), `Gallery/GalleryRootView.swift`, `Gallery/PhotoGrid.swift` (scroll position), `Gallery/GalleryViewModel.swift` (`photos(in:)`)
- New: `Gallery/Tests/GalleryUITests/ParallaxTests.swift`; edit `GalleryViewModelTests.swift`, `ZoomTransformTests.swift` if anything moves
- Edit: `AppUITests/GalleryAppUITests.swift` (swipe left in full screen → the title shows the second Photo's Caption)

## Tests (one at a time)

1. `Parallax.offset`: page centred (minX 0) → 0.
2. One page to the right (minX = width) → `-factor × width`; one to the left → `+factor × width`.
3. Beyond one page → clamped to ±`factor × width`.
4. View model: `photos(in: "feed")` returns the feed's Photos; `photos(in: "search-cats")` the Search results; unknown → `[]`.
5. View model: a Photo appearing near the end of the feed from full screen triggers exactly one load more (reuse the existing load-more tests' spy).

## Decision log + ADR 0007

- Full screen shows a Stream, not a Photo: swiping pages through the feed or the current Search results, with parallax and load more. Why: it's the main thing users expect from a photo viewer, and the Stream already owns paging. Cost: the route carries a Stream id, and the zoom-back target follows the current Photo.

## Commit

Split if it grows: `refactor(ui): extract the zoomable photo page`, then `feat(ui): swipe between photos in full screen with parallax`.
