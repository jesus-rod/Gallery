# 03 — Cell image model: no work on redraw, image fades in over the Preview

Status: ready-for-agent
Blocked by: none

Three findings in the same two types, fixed together.

1. `PhotoCell.init` runs `State(initialValue: PhotoImageModel(photo:images:))` on every parent redraw. SwiftUI keeps only the first model, but each discarded one still ran `images.preview(photo)` on the main thread (an `NSCache` lookup, a BlurHash decode on a miss).
2. The Preview branch is removed in the same animated change that inserts the image, so the two cross-fade and the grey `.quaternary` fill shows through mid-fade. M3 spec: "image fades in over the Preview".
3. M3 ticket 10 asked for "Cancelled load leaves the state unchanged"; there is no test.

The same init pattern exists in `FullScreenImageModel` (M5 ticket 03); apply fix 1 there too, so ticket 05 starts from the fixed shape.

## Files

- Edit: `Gallery/Sources/GalleryUI/Images/PhotoImageModel.swift`
- Edit: `Gallery/Sources/GalleryUI/FullScreen/FullScreenImageModel.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/PhotoGrid.swift` (`PhotoCell` body)
- Edit: `Gallery/Tests/GalleryUITests/PhotoImageModelTests.swift` (`PhotoImagesSpy` counts preview calls)
- Edit: `Gallery/Tests/GalleryUITests/FullScreenImageModelTests.swift`
- Edit: `docs/decision-log.md`

## Shape

```swift
@Observable @MainActor
final class PhotoImageModel {
    var preview: CGImage? { get }      // looked up on first read, then memoized (@ObservationIgnored storage)
    private(set) var image: CGImage?   // nil until loaded
    var isLoaded: Bool { image != nil }
    init(photo: Photo, images: PhotoImages)   // does no work: stores its inputs only
    func load(size: ImageSize) async
}
```

- The `State` enum goes away: Preview and image are separate, so the view can keep the Preview underneath.
- A model SwiftUI discards is never read, so it never looks up its Preview. The kept model reads it in its first `body`, so the cell still has its Preview on its very first frame (M3 decision).
- `PhotoCell` body: the Preview layer is drawn whenever `preview` is non-nil and is never removed; the image layer is inserted on top with `.transition(.opacity)`. Only the image's insertion is animated.
- `FullScreenImageModel`: same lazy, memoized Preview; its init does no work. Keep its tested ordering behaviour (never steps down); adapt its state shape only as far as the lazy Preview needs, and keep the Preview available under the grid and full images so ticket 05 can layer them the same way.

## Tests (one at a time, red → green)

`PhotoImageModelTests` (rewrite the state assertions to the new shape; behaviour is unchanged):
- `init_doesNotLookUpThePreview` (spy preview call count 0)
- `preview_isLookedUpOnceOnFirstRead` (read twice → count 1)
- `load_showsTheLoadedImageAndKeepsThePreview`
- `load_keepsNoImageOnFailure`
- `load_keepsTheLoadedImageWhenALaterLoadFails`
- `load_cancelledLeavesTheImageUnchanged` (finding 3: gate the image, cancel the loading task, open the gate → `image == nil`)
- `isLoaded_isTrueOnlyOnceTheImageIsShown`

`FullScreenImageModelTests`: add `init_doesNotLookUpThePreview` and `preview_isLookedUpOnceOnFirstRead`; keep every existing ordering test green, adapting assertions only to the new shape.

## Acceptance

- Tests pass; `swift test` green; lint clean; app builds; the six existing XCUITests (and any M5 ones by then) pass.
- Visual check in the `#Preview` or simulator: the image fades in over the Preview with no grey flash.

## Decision log

- Image models do no work in `init`: SwiftUI rebuilds a view's `State(initialValue:)` argument on every parent redraw and keeps only the first, so the Preview is looked up lazily on first read and memoized.
- The Preview stays underneath and the image fades in on top, instead of cross-fading the two, which showed the grey cell fill mid-fade.

## Commit

`fix(ui): build cell image models lazily and fade the image over the Preview`
