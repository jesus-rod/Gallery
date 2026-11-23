# M5 — Full-screen view

Status: spec agreed on decisions; seams and tickets next

## Goal

Tapping a Photo in either Stream opens its Full-screen view: the Photo fitted to the screen on black, with its Caption and Photographer credit. The cached grid image shows at once, and a sharper Rendition sized for the screen loads over it. Pinch and double-tap zoom, drag down or Close to go back to the grid at the same scroll position. On iOS 18+ the Photo zooms out of its cell; on iOS 17 it uses the standard push.

## Use cases

**Open a Photo**
- Happy: tap a cell in the Editorial feed or in Search results → the Full-screen view is pushed. It shows the best image already on the device first (grid image from the memory cache, else the Preview), then the full-screen Rendition fades in over it.
- The full-screen Rendition fails to load → the grid image (or Preview) stays; no error screen. Closing and reopening tries again.
- Rotation or an iPad window resize → a Rendition for the new size is requested; the current image stays until it arrives.
- Opening a Photo costs no API request: Renditions come from the CDN, outside the Request budget.

**Zoom**
- Pinch zooms between 1× and 4× around the pinch point; pinching below 1× stays at 1×.
- Double tap at 1× zooms to 2.5× centred on the tapped point; double tap when zoomed goes back to 1×.
- When zoomed, a drag pans the image, and the image edges never come inside the screen edges.

**Close**
- Drag down at 1×: the Photo follows the finger and the background fades; past the threshold (distance or flick) the view closes, otherwise it springs back. When zoomed, a drag pans instead.
- Close button (top leading) closes it. VoiceOver's escape gesture closes it too.
- The grid underneath keeps its Photos and scroll position, so closing costs nothing (same `NavigationStack`, nothing reloads).

**Overlay**
- The bottom overlay shows the Caption and "Photo by <Photographer> on Unsplash". The Photographer's name and "Unsplash" are links with Unsplash's referral parameters (`utm_source=<app name>&utm_medium=referral`), as the API guidelines require.
- A single tap toggles the overlay and the Close button; zooming in hides them, back at 1× they stay as the person left them.

**Accessibility**
- The image is one element labelled with the Caption, with the `.isImage` trait. The credit is readable and its links are actionable. Dynamic Type for the overlay text. Close has a label.

**Run on fixtures**
- With `-useStubs`, the full-screen Rendition is answered by `StubImageHTTPClient` (it routes on the last path component, so any query works). One XCUITest opens a Photo from the feed and closes it.

## Seams under test

| Seam | Observed through |
|---|---|
| `UnsplashRendition.fullScreen(for:fitting:scale:quality:)` | URL query items (`w`, `dpr`, `q`, `fm`, existing items kept) and `maxPixelSize`, for landscape, portrait, square and zero-size Photos and containers |
| `UnsplashAttribution.referralURL(_:appName:)` | Resulting URL: existing query items kept, `utm_source` and `utm_medium=referral` added or replaced |
| `FullScreenImageModel(photo:images:gridSize:)` | `state` after `load(fitting:)`, given stubbed `PhotoImages` closures that complete in a chosen order or fail |
| `ZoomTransform` (pure value) | `scale`, `offset`, `shouldDismiss`, `dismissProgress` after magnify, double tap, pan and drag inputs |
| `FullScreenImageModel` lifetime | Deallocated after every test (`.trackingLeaks`) |
| App end to end | One XCUITest journey with `-useStubs`: tap a feed cell → Full-screen view with Caption and credit → Close → same cell still on screen. Opening from Search results uses the same route code and gets no separate UI test. |

`FullScreenPhotoView`, the overlay and the transition stay logic-free (they read `FullScreenImageModel.state` and `ZoomTransform`) and are covered by `#Preview`s and the XCUITests. Gesture feel is checked by hand on device in ticket 07.

## Shape

**Navigation.** `GalleryRootView` holds `@State private var path: [FullScreenRoute]`, uses `NavigationStack(path:)` and `.navigationDestination(for: FullScreenRoute.self)`. A cell opens a Photo with `.onTapGesture` plus a default `.accessibilityAction`, which appends a route; it is not wrapped in a `NavigationLink`, because a button would change the cell's accessibility element type from image to button and break every existing XCUITest query (`app.images[…]`). Both grids sit in the same `NavigationStack`, so either can push and the feed's hidden-`ZStack` trick from M4 keeps working underneath.

```swift
struct FullScreenRoute: Hashable {             // internal, GalleryUI/FullScreen/FullScreenRoute.swift
    let photo: Photo
    let gridSize: ImageSize                    // the cell's size, to find the grid image in the memory cache
    let sourceID: String                       // "<stream>-<photo id>": the zoom transition's source
}
```

`Photo` (and `Renditions`, `Photographer`) become `Hashable` in Core; every stored property already is. `sourceID` includes the Stream because the same Photo can be in the hidden feed and in Search results at once, and two transition sources with one ID would zoom from the wrong (invisible) cell.

**Zoom transition (iOS 18+).** The cell gets `.matchedTransitionSource(id: sourceID, in: namespace)`, the destination `.navigationTransition(.zoom(sourceID:in:))`, both behind `if #available(iOS 18, *)` in small `View` extensions. On iOS 17 the standard push is used (decision 2).

**Image loading.** `PhotoImages` gains one closure; the composition root builds it from the full-screen Rendition and the same memory cache, so the full-screen image goes through the whole pipeline (memory, disk, dedup).

```swift
public struct FittingSize: Hashable, Sendable {   // GalleryUI/Images/PhotoImages.swift
    public let width: Double                      // points
    public let height: Double
    public let scale: Double
}

public struct PhotoImages: Sendable {
    public typealias LoadFullScreenImage = @Sendable (Photo, FittingSize) async throws -> CGImage
    let fullScreenImage: LoadFullScreenImage
    // preview, image, prefetch, prefetchDistance unchanged
}

@MainActor @Observable
final class FullScreenImageModel {                // internal, GalleryUI/FullScreen/FullScreenImageModel.swift
    enum State: Equatable {
        case preview(CGImage?)
        case gridImage(CGImage)
        case fullImage(CGImage)
    }
    private(set) var state: State
    init(photo: Photo, images: PhotoImages, gridSize: ImageSize)
    func load(fitting size: FittingSize) async    // grid image and full image requested concurrently;
                                                  // never downgrades (a late grid image after the full one is ignored);
                                                  // a failed full image keeps what is shown
}
```

The view drives it with `.task(id: fittingSize)`, so rotation requests a new size and leaving the view cancels the load.

**Rendition (Core).** `UnsplashRendition.Grid` is renamed `UnsplashRendition.Sized` (it is just URL + max pixel size). New:

```swift
public static func fullScreen(for photo: Photo, fitting width: Double, height: Double, scale: Double, quality: Int) -> Sized
```

It aspect-fits the Photo into the container, requests `w = fittedWidth` with `dpr = scale` from `raw` through the existing `gridURL` builder (renamed `sizedURL`), and sets `maxPixelSize` to the fitted longest side × scale. A zero container or zero-size Photo falls back to fitting a square, like `grid`.
**Zoom maths (UI, pure).**

```swift
struct ZoomTransform: Equatable {                 // internal, GalleryUI/FullScreen/ZoomTransform.swift
    private(set) var scale: Double = 1            // always within 1…4
    private(set) var offset: CGSize = .zero       // always clamped so the image covers the container edges it overflows
    var isZoomed: Bool { get }
    func magnified(by magnification: Double, anchor: CGPoint, container: CGSize, content: CGSize) -> ZoomTransform
    func toggled(at point: CGPoint, container: CGSize, content: CGSize) -> ZoomTransform
    func panned(by translation: CGSize, container: CGSize, content: CGSize) -> ZoomTransform
    static func dismissProgress(for translation: CGSize) -> Double        // 0…1, drives the background fade
    static func shouldDismiss(translation: CGSize, predictedEnd: CGSize) -> Bool
}
```

The functions return a new value from a starting one: the view keeps the transform at the start of a gesture and applies the gesture's cumulative value to it on every change. `content` is the fitted image size in points. Gestures in the view (`MagnifyGesture`, `SpatialTapGesture(count: 2)`, `DragGesture`) only forward values into `ZoomTransform`. The drag means "dismiss" at 1× (iOS 17, decision 3) and "pan" when zoomed. Pinching below 1× stays at 1×, with no rubber band.

**Attribution (Core).** `UnsplashAttribution.referralURL(_ url: URL, appName: String) -> URL`. The app name is passed into `GalleryRootView(viewModel:images:referralAppName:)` by the composition root, so no string is hard-coded in the UI module.

## Decisions taken with the user (2026-11-23)

1. **Full-screen Rendition sized from `raw` to the screen**, not `regular`. `regular` (1080 px wide) is too small for an iPhone Pro Max in portrait (1320 px) and for any iPad, and wasteful for a landscape Photo on a small phone; sizing from `raw` reuses the tested URL builder. This replaces the roadmap's "full screen uses `regular`" and gets a decision-log line in ticket 01.
2. **Standard push on iOS 17**, not a cross-fade. `NavigationStack` has no cross-fade push; faking one means presenting over the stack, losing the back gesture and the iOS 18 zoom path. Decision-log line in ticket 05.
3. **Drag to dismiss: the system zoom gesture on iOS 18+, our own drag on iOS 17.** On iOS 18+ our drag only pans when zoomed. Ticket 05 first checks on device that the system gesture does not fight panning a zoomed Photo; if it does, our own drag dismisses on both versions and that goes in the decision log.
4. **Referral app name `gallery_ios`**, passed in by the composition root.
5. **Close button always available**, shown and hidden with the overlay. Drag down is not discoverable and is unavailable to VoiceOver users.

## Tickets (in order)

01 `Photo: Hashable`, rename `Grid` → `Sized`, `UnsplashRendition.fullScreen` (Core, TDD) · 02 `UnsplashAttribution.referralURL` (Core, TDD) · 03 `FittingSize`, `PhotoImages.fullScreenImage`, `FullScreenImageModel`, composition root wiring (UI, TDD) · 04 `ZoomTransform` (UI, TDD) · 05 `FullScreenPhotoView`, overlay, navigation from both grids, zoom transition, gestures, previews, strings · 06 one XCUITest journey · 07 review, docs, roadmap, device check (gesture feel, rotation, memory with ~20 full-screen opens in Instruments).

## Out of scope

Swiping left and right between Photos in the Full-screen view, loading a bigger Rendition when zoomed past 1×, sharing or saving, Photo statistics or EXIF, prefetching full-screen Renditions, Offline feed (M6), snapshot tests (M7).

## Carried items

- Ticket M3/12 (live run with a real key) still waits on the user. Ticket 07 adds opening a Photo full screen to that run; it costs no API request.
- Search edges from the M4 review (refresh banner hidden during search, no pull to refresh on Search results, hidden feed can finish a load more): unchanged by M5.
- Carried to M7, untouched here: synchronous memory-cache lookup to skip the Preview fade. It matters more now, because the full-screen view could then show the grid image on its very first frame instead of one async hop later. Snapshot tests stay in M7.
- Full-screen images (about 9 MB decoded on a Pro Max) share the memory cache with grid images. Ticket 07 measures whether opening many Photos evicts the visible grid; if it does, a separate small cache for full-screen images is the fix.
- Mapper helper: still no third mapper, not extracted.
- EF-97 vs swift-format: the linter wins.
- Lint all three folders: `swift format lint -r Gallery App AppUITests`.

## Pattern notes

Same moves as M3: the UI decides *when* and *at what size* it needs an image (`FittingSize`), the composition root decides *which URL and which caches* (`PhotoImages.fullScreenImage`). The only new logic with branches, `FullScreenImageModel` ordering and `ZoomTransform` maths, sits in types testable on macOS without SwiftUI views; the views just forward gestures and render state.

## Rules for the implementer

- TDD per ticket: one failing test (Swift Testing: `@Test`, `#expect`, `@Suite(.trackingLeaks)`), minimal code to green, repeat. Every SUT goes through `makeSUT`, which calls `trackForMemoryLeaks`. XCUITest only for app end to end.
- Commands: `cd Gallery && swift test`; from the repo root `swift format lint -r Gallery App AppUITests` (fix with `swift format -i -r Gallery App AppUITests`). App build: `xcodebuild build -project Gallery.xcodeproj -scheme GalleryApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`. UI tests: `xcodebuild test -project Gallery.xcodeproj -scheme GalleryApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GalleryAppUITests`.
- No code comments anywhere. Swift 6 strict concurrency, `@Observable @MainActor` models, iOS 17 minimum; iOS 18 APIs only behind `#available`.
- `App/` and `AppUITests/` are synchronized folder groups: new files there need no `project.pbxproj` edits. Do not commit the Xcode format rewrites of `project.pbxproj` and the scheme.
- Each notable decision goes into `docs/decision-log.md` under a `## M5 — Full-screen view` heading (created in ticket 01), in the same commit as the code.
- One commit per ticket, conventional style like the existing log, 2–4 line body, the ticket's `Status: done` in the same commit. Authored by the user with plain `git commit`, never a `Co-Authored-By` or Claude attribution line. Propose the commit message and wait for the user's approval before committing.
