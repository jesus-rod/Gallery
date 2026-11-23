# 03 — `FullScreenImageModel` and the full-screen image closure

Status: done
Blocked by: 01

The Full-screen view shows the best image already on the device, then the sharp one. This ticket adds the closure that loads it and the small model that decides what is shown, and wires the closure in the composition root. No view yet.

## Files

- Edit: `Gallery/Sources/GalleryUI/Images/PhotoImages.swift` (`FittingSize`, `fullScreenImage`)
- New: `Gallery/Sources/GalleryUI/FullScreen/FullScreenImageModel.swift`
- New: `Gallery/Tests/GalleryUITests/FullScreenImageModelTests.swift`
- Edit: `Gallery/Tests/GalleryUITests/PhotoImageModelTests.swift` (`PhotoImagesSpy` gains the new closure; see below)
- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryPreviews.swift` (pass a `fullScreenImage` closure, same style as `image`)
- Edit: `Gallery/Sources/GalleryImageLoading/ImagePipelineConfiguration.swift` (`fullScreenRenditionQuality`, default 80)
- Edit: `App/ImagePipeline.swift`
- Edit: `docs/decision-log.md`

## Shape

```swift
public struct FittingSize: Hashable, Sendable {
    public let width: Double
    public let height: Double
    public let scale: Double
    public init(width: Double, height: Double, scale: Double)
}

public struct PhotoImages: Sendable {
    public typealias LoadFullScreenImage = @Sendable (Photo, FittingSize) async throws -> CGImage
    let fullScreenImage: LoadFullScreenImage
    public init(preview:image:fullScreenImage:prefetch:prefetchDistance:)   // new parameter after image, no default
}

@MainActor
@Observable
final class FullScreenImageModel {
    enum State: Equatable {
        case preview(CGImage?)
        case gridImage(CGImage)
        case fullImage(CGImage)
    }
    private(set) var state: State
    var isFullImageShown: Bool { get }
    init(photo: Photo, images: PhotoImages, gridSize: ImageSize)   // state = .preview(images.preview(photo))
    func load(fitting size: FittingSize) async
}
```

`load(fitting:)`:
- Unless a full image is already shown, request the grid image (`images.image(photo, gridSize)`) and the full image (`images.fullScreenImage(photo, size)`) concurrently in a `withTaskGroup`, applying each result as it arrives.
- A grid image is applied only while the state is `.preview`. A full image always replaces what is shown. Failures change nothing.
- When a full image is already shown (rotation), only the full image is requested.
- Cancelling the calling task (the view's `.task(id:)`) cancels both child loads.

`PhotoImagesSpy`: add a separately stubbed full-screen result and a `fullScreenRequests: [FullScreenRequest(photoID, size)]` list. For ordering tests, let each closure optionally wait on a `Gate` (existing helper) before returning, so a test can release the grid and full results in a chosen order.

Composition root (`ImagePipeline.photoImages`): `fullScreenImage` builds `UnsplashRendition.fullScreen(for:fitting:height:scale:quality: configuration.fullScreenRenditionQuality)` and loads it through `memoryCache.loadImage(from:maxPixelSize:)`, so it goes through memory, disk, dedup and remote like the grid.

## Tests (one at a time, red → green; `@Suite(.trackingLeaks)`, `makeSUT`)

- `init_showsThePhotosPreview`
- `load_requestsTheGridImageAtTheGridSizeAndTheFullImageAtTheFittingSize`
- `load_showsTheGridImageWhileTheFullImageIsLoading` (full gated, grid succeeds → `.gridImage`)
- `load_showsTheFullImage`
- `load_keepsTheFullImageWhenTheGridImageArrivesLater` (full first, then grid → still `.fullImage`)
- `load_keepsTheGridImageWhenTheFullImageFails`
- `load_keepsThePreviewWhenBothFail`
- `load_requestsOnlyTheFullImageOnceItIsShown` (second load with a new size: no new grid request)
- `load_keepsTheShownFullImageWhenANewSizeFails`
- `load_replacesTheFullImageWithTheOneForTheNewSize`
- `isFullImageShown_isTrueOnlyForTheFullImage`

## Acceptance

- Tests above and every existing test pass (the spy and previews updated for the new init parameter).
- App builds; `swift format lint -r Gallery App AppUITests` clean.

## Decision log

- The Full-screen view asks for the grid image (a memory-cache hit, since the cell just showed it) and the full-screen Rendition at the same time, and never steps down: Preview → grid image → full image. A failed full image leaves the grid image; there is no error screen for it.
- The full-screen Rendition goes through the same pipeline and memory cache as the grid, with its own quality setting (80, grid 75), so reopening a Photo is instant.

## Commit

`feat(ui): load the full-screen image over the cached grid image`
