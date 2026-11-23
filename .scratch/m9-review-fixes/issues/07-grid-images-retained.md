# 07 — Grid cells keep their decoded images after scrolling away

Status: code done (278 tests green, lint clean), commit proposed; the user's Run B re-record and the write-up are still to do, see "Next". The optional simulator probe (step 1) was skipped: the device re-record answers the same question.
Blocked by: none

## Finding (Instruments Run B, `allocations-intruments.trace`, iPhone 15 Plus, Release, 2026-11-23 20:55)

Steps: 0–50 s scroll the feed (~500 images), 50–90 s open and close ~20 photos, 90–152 s swipe in full screen to the end.

- End of run: **1.17 GB persistent** (All Heap & Anonymous VM), of which **1.135 GB is VM: CG Raster Data in 438 live images**. The memory cache is capped at 100 MB.
- By creation time of the images still alive at the end: scroll phase 410 images / 1009 MB (avg 2.5 MB = a grid rendition, 640 px wide portrait); open/close 19 / 64 MB; full-screen swipe only 9 / 62 MB. So full-screen pages are released (a first guess that `FullScreenImageModel` kept them was wrong and was reverted); the grid is the problem.
- All created by `DownsamplingImageLoader.downsample`; stacks end at the async boundary, so the holder isn't in the trace. Only ~40 grid images fit the 100 MB cache, so ~370 are held elsewhere: each cell's `@State` `PhotoImageModel` keeps `loadedImage` (and the memoized `cachedStorage`), and SwiftUI keeps lazy-grid cell state after cells scroll off.

How the numbers were read: `xctrace export` of `detail[@name="Statistics"]` and `detail[@name="Allocations List"]` (live allocations only, 287 MB XML; parse with `iterparse`, filter `category="VM: CG Raster Data"`, timestamps `MM:SS.mmm`).

## Fix (uncommitted in the working tree)

- `PhotoImageModel.release()`: drops `loadedImage` and the memoized `cachedStorage`, so the next read asks the memory cache again. Tests: `release_dropsTheLoadedImage`, `release_asksTheCacheAgainOnTheNextRead`.
- `PhotoCell` and `HeroHeader`: `.onDisappear(perform: model.release)`. On reappear, `.task(id:)` runs again and `load` takes the image from the memory cache (no fade, `wasCachedOnAppear`) or the disk cache.

## Risks to check

- Pushing full screen fires `onDisappear` on the grid's cells, so they release; on zoom back, the target cell re-reads the cache. If the full-screen images pushed its grid image out of the 100 MB cache, the zoom lands on the BlurHash Preview for a moment. Check by eye on device.
- Scrolling back up re-reads from the memory or disk cache; should be invisible.

## Next

1. Optional local check (was in progress): shrink `memoryCostLimit` to 10 MB temporarily in `ImagePipelineConfiguration.default`, run a throwaway XCUITest that scrolls the 60 stub photos down and up (`AppUITests/ZZMemoryProbe.swift`, never commit), and record Allocations on an **iOS 27.2 simulator** with `xctrace record --template Allocations --device <udid> --attach <pid>`; compare CG Raster persistent bytes with and without the fix. `vmmap` can't read simulator apps on this macOS. Revert both temp changes after.
2. Commit the fix (`fix(ui): release grid images when cells scroll away`), then the user re-records Run B (Allocations template only; ~25 requests); compare persistent CG Raster Data (target: about the 100 MB cache plus visible cells).
3. Decision log line under `## Review fixes (M9)`; README Performance table (Allocations row).
