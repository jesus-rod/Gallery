# 03 — Images already in memory show on the first frame

Status: done
Blocked by: none

## Files

- Edit: `Gallery/Sources/GalleryImageLoading/MemoryCachingImageLoader.swift`, tests in `MemoryCachingImageLoaderTests.swift`
- Edit: `Gallery/Sources/GalleryUI/Images/PhotoImages.swift` (new `cachedImage` closure, init parameter after `preview`)
- Edit: `Gallery/Sources/GalleryUI/Images/PhotoImageModel.swift`, `Gallery/Sources/GalleryUI/FullScreen/FullScreenImageModel.swift`, their tests and `PhotoImagesSpy`
- Edit: `Gallery/Sources/GalleryUI/Gallery/PhotoGrid.swift` (fade only for late arrivals), previews (`FullScreenPreviews.swift`, `GalleryPreviews.swift`)
- Edit: `App/ImagePipeline.swift` (`cachedImage` builds the grid Rendition and asks `memoryCache.cachedImage`)
- Edit: `docs/decision-log.md`

## Tests (one at a time)

ImageLoading:
1. `cachedImage` returns nil before any load.
2. Returns the image after `loadImage` for the same URL and size; nil for another size.
3. Returns nil after `removeAll()`.
4. Never calls the decoratee.

UI:
5. `PhotoImageModel.image` is the cached image before `load`, and `isLoaded` is true.
6. `load` with a cached image requests nothing.
7. `cachedImage` is called once even when `image` is read many times (memoized; init does no work).
8. `FullScreenImageModel` starts in `.gridImage` when the grid image is cached; `load` then requests only the full image.

## View

The cell keeps the Preview + fade only when the image arrives after the cell first appeared: track `@State private var didLoadAfterAppear` (or equivalent) and drive `.animation` from it, not from `isLoaded`.

## Decision log

- Images already in the memory cache are read synchronously (`NSCache` is thread safe) through a `PhotoImages.cachedImage` closure, so a cell scrolled back into view or a reopened Photo shows its image on the first frame, with no Preview and no fade.

## Commit

`perf(ui): show images already in memory on the first frame`

## Comments

- `PhotoImageModel.init` gained a `size` parameter (the lookup needs the grid size before `load`). The fade is driven by `PhotoImageModel.wasCachedOnAppear` (memoized first lookup) instead of a `didLoadAfterAppear` view flag; the cell also skips the Preview layer when the image was cached.
