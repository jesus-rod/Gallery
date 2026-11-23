# 01 — Full-screen Rendition and `Photo: Hashable`

Status: done
Blocked by: none

Core only. Three changes, in this order:

1. **Refactor, no behaviour change.** Rename `UnsplashRendition.Grid` to `UnsplashRendition.Sized` and `gridURL(raw:pointWidth:scale:quality:)` to `sizedURL(raw:pointWidth:scale:quality:)`. Rename the existing `gridURL_…` tests to `sizedURL_…` (names only, bodies unchanged). Update `App/ImagePipeline.swift`, which uses `UnsplashRendition.Grid`. All tests stay green.
2. **`Photo`, `Photo.Renditions` and `Photo.Photographer` become `Hashable`** (needed by `FullScreenRoute` in ticket 05). Every stored property is already `Hashable`, so the conformance is synthesized. No test: it is a compile-time requirement.
3. **TDD `UnsplashRendition.fullScreen`.**

## Files

- Edit: `Gallery/Sources/GalleryCore/UnsplashAPI/UnsplashRendition.swift`
- Edit: `Gallery/Sources/GalleryCore/Photos/Photo.swift`
- Edit: `Gallery/Tests/GalleryCoreTests/UnsplashRenditionTests.swift`
- Edit: `App/ImagePipeline.swift` (type rename only)
- Edit: `docs/decision-log.md` (add the `## M5 — Full-screen view` heading at the end)

## Shape

```swift
public static func fullScreen(for photo: Photo, fitting width: Double, height: Double, scale: Double, quality: Int) -> Sized
```

- Aspect ratio as in `grid`: `photo.width / photo.height`, or `1` when either is zero.
- Fit the Photo into `width × height` points: `fittedWidth = min(width, height × aspectRatio)`, `fittedHeight = fittedWidth / aspectRatio`.
- `url = sizedURL(raw: photo.renditions.raw, pointWidth: fittedWidth, scale: scale, quality: quality)`.
- `maxPixelSize = Int((max(fittedWidth, fittedHeight) × scale).rounded(.up))`.
- The view never asks for a zero-size container (it guards like the grid does), so that case is not specified or tested.

## Tests (one at a time, red → green)

Container `400 × 800` points, `scale: 3`, `quality: 80` unless stated. Check `w` and `dpr` in the URL's query items and `maxPixelSize`.

- `fullScreen_fitsALandscapePhotoToTheContainerWidth`: 4000 × 3000 → `w=400`, `dpr=3`, `maxPixelSize == 1200`.
- `fullScreen_fitsAPortraitPhotoToTheContainerWidthWhenItIsShortEnough`: 3000 × 4000 → `w=400`, `maxPixelSize == 1600` (533.33 × 3, rounded up).
- `fullScreen_fitsATallPhotoToTheContainerHeight`: 1000 × 4000 → `w=200`, `maxPixelSize == 2400`.
- `fullScreen_fitsAPortraitPhotoInALandscapeContainer`: container 800 × 400, 3000 × 4000 → `w=300`, `maxPixelSize == 1200`.
- `fullScreen_treatsAPhotoWithoutDimensionsAsSquare`: 0 × 0 → `w=400`, `maxPixelSize == 1200`.
- `fullScreen_buildsFromTheRawRenditionWithQualityAndJPEGFormat`: host and path are the raw URL's, its existing query items are kept, `q=80`, `fm=jpg`.

## Acceptance

- All tests above, plus every existing Core test, pass. `UnsplashRendition.Grid` and `gridURL` no longer exist.
- `swift test` green, `swift format lint -r Gallery App AppUITests` clean, app builds.

## Decision log

Under a new `## M5 — Full-screen view` heading:
- The full-screen Rendition is sized from `raw` to the screen (aspect fit × display scale), replacing the earlier plan to use `regular`: `regular` is 1080 px wide, softer than an iPhone Pro Max (1320 px) or any iPad, and too big for a landscape Photo on a small phone. It reuses the grid's URL builder, renamed `sizedURL`.
- `Photo` is `Hashable` so it can be a navigation value; it is still not `Codable`.

## Commit

`feat(core): size the full-screen Rendition to the screen` with a body naming the `Grid` → `Sized` rename and `Photo: Hashable`.
