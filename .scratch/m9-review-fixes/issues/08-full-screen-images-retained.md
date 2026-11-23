# 08 — Full-screen pages keep their decoded images after swiping past

Status: code done (280 tests green, lint clean), not yet verified on device; commit pending the user's OK
Blocked by: none

## Finding

Swipe-only Allocations trace (`allocations-intruments-2.trace`, iPhone 15 Plus, iOS 27.0.1, Release, 50 s): at the end, 306 MB persistent, 285 MB of it decoded images in 101 CG Raster allocations. Surviving images were created steadily through the swipe (8–20 per 5 s), not in a burst, so they were kept rather than released after each page.

Cause (read from code): `PagerWindow` only decides which pages load the full image; each `ZoomablePhotoPage` owns a `FullScreenImageModel` in `@State`, and `LazyHStack` keeps page state after a page scrolls away, as it did for grid cells. The model's `loadedState` (full image) and `cachedGridStorage` were never released.

## Fix

- `FullScreenImageModel.release()`: drops `loadedState` and the memoised grid image, so the next read asks the cache again.
- `ZoomablePhotoPage`: `.onDisappear(perform: model.release)`. On reappear, `.task(id:)` runs and loads from the memory or disk cache.
- Tests (test first, red then green): `release_dropsTheShownFullImage`, `release_asksTheCacheForTheGridImageAgain`.

## Still to verify

- Device Allocations run over the whole session (grid scroll, then full-screen swipe), with step times written down. Expect persistent CG Raster well below the swipe-only 285 MB.
- Check on device that swiping back to a page reloads it without a visible flash, and that the zoom back to the grid cell still lands on the image.
- Open question (M5): full-screen images share the 100 MB memory cache with grid images; check whether they evict visible grid images.
