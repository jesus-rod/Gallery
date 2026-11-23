# M7 — Polish: UX states and accessibility

Status: done

## Goal

Close the UX and accessibility gaps carried from M3–M5: an "invalid key" state instead of the generic error, pull to refresh on Search results, no Preview flash or fade for images already in memory, VoiceOver frames that match what is on screen, Reduce Motion and large Dynamic Type handled, and snapshot tests for the cell and the state views.

## Use cases

1. A wrong or missing access key (Unsplash answers 401) shows "Access key not accepted" with a hint to check `Config/Secrets.xcconfig`, in the feed and in Search results.
2. Pull to refresh on Search results reloads the Query's first Page; failure keeps the results and shows the brief refresh error, also while searching (today that banner is hidden during search).
3. Scrolling back up, or reopening a Photo, shows images already in the memory cache on the first frame, with no Preview and no fade.
4. VoiceOver's focus box for a grid cell is the cell, and for the full-screen Photo is the visible image.
5. With Reduce Motion on, images appear without a fade and the overlay toggles without animation.
6. At accessibility Dynamic Type sizes, the full-screen overlay, banners and state views stay readable (wrap, scroll if needed, never truncate the credit).

## Seams under test

| Seam | Observed through |
|---|---|
| `EditorialPhotosMapper` / `SearchPhotosMapper` | 401 → `UnsplashAPIError.unauthorized` (403 with `X-Ratelimit-Remaining: 0` stays `rateLimited`) |
| `LoadError(_:)` | `.unauthorized` → `.invalidKey` |
| `GalleryViewModel.refreshSearch()` | `searchResults` and `refreshError` after success and failure with stubbed `search` |
| `MemoryCachingImageLoader.cachedImage(from:maxPixelSize:)` | Returns the image after a load, nil before, nil after `removeAll()`; never calls the decoratee |
| `PhotoImageModel` / `FullScreenImageModel` | `image` / `state` available before any `load` when `PhotoImages.cachedImage` returns one; `load` then requests nothing for the grid image |
| Views (cell, `LoadErrorView` per error, `EmptySearchView`) | Snapshot images, light and dark, on macOS (`swift test`), with swift-snapshot-testing as a test-only dependency |
| App end to end | No new journey. The feed journey gains one assertion: the first cell's frame is no wider than half the grid |

## Shape

```swift
// GalleryCore
public enum UnsplashAPIError: Error, Equatable { case invalidData, rateLimited, unauthorized }

// GalleryImageLoading
extension MemoryCachingImageLoader { public func cachedImage(from url: URL, maxPixelSize: Int) -> CGImage? }

// GalleryUI
public struct PhotoImages {
    public typealias CachedImage = @Sendable (Photo, ImageSize) -> CGImage?
    let cachedImage: CachedImage          // new init parameter after `preview`; previews and tests pass `{ _, _ in nil }` where they don't care
}
extension GalleryViewModel { public func refreshSearch() async }
public enum LoadError { case offline, rateLimited, invalidKey, generic }
```

`PhotoImageModel.image` starts from `cachedImage` on first read (lazily and memoized, like `preview`, because SwiftUI rebuilds `State(initialValue:)` arguments on every parent redraw). The cell animates the fade only when the image arrives after the first frame (drive the animation from a `didLoadAfterAppear` flag, not from `isLoaded`). `FullScreenImageModel` starts in `.gridImage` when the grid image is cached, so `load` requests only the full image.

## Decisions (new)

- 401 gets its own state because it is the most likely first-run failure for a reviewer setting up the key; the message names the config file.
- The memory-cache lookup is synchronous (`NSCache` is thread safe) and lives behind a new `PhotoImages` closure, so views stay unaware of URLs and caches.
- The hidden feed may still finish an in-flight load more while searching; accepted, since it costs at most one request the user already triggered and keeps the feed consistent when search is cancelled.
- Snapshot tests render on macOS in `swift test` (fast, no simulator), recorded at a fixed size in light and dark; they guard layout regressions, not pixel-exact iOS rendering.

## Tickets (in order)

01 401 → invalid key state (Core + UI, TDD) · 02 pull to refresh on Search results (UI, TDD) · 03 synchronous memory-cache hit, no Preview or fade (ImageLoading + UI, TDD) · 04 VoiceOver frames, Reduce Motion, Dynamic Type pass · 05 snapshot tests · 06 review notes, spec done.

## Review notes

Quick essential-feed pass over the M7 commits.

- Views depend only on `PhotoImages` closures (`cachedImage` is the only new one); no view knows about URLs, caches or the pipeline. `App/ImagePipeline.swift` is the only place that builds the grid Rendition for the lookup.
- `GalleryCore` and `GalleryImageLoading` still import neither each other nor `GalleryUI`; the only new dependency is test-only (swift-snapshot-testing on `GalleryUITests`).
- No code comments in the M7 diff; no iOS 18 API added (the zoom transition stays behind `#available` from M5).
- Class SUTs (`MemoryCachingImageLoader`, `PhotoImageModel`, `FullScreenImageModel`) are built through `makeSUT` with leak tracking; `GalleryViewModel` tests use the existing `makeSUT`.
- Tests were written one at a time, with exceptions: the Search mapper 401 test came right after the shared `requireDecodable` helper (a refactor of the Editorial change), and some tests passed on arrival because the minimal code of the previous test already covered them (`refreshSearch` tests 2 and 3, `PhotoImageModel.image` before load).
- Found by the UI tests, not by unit tests: a full-screen layer holding a single Button merges into it for accessibility and reports the whole screen as the button's frame. The Close layer is now `.accessibilityElement(children: .contain)`. Worth remembering for any future overlay with one control.

Open, carried to M8:
- VoiceOver itself and the Accessibility Inspector were not run: focus boxes, the Close, image, Caption, credit order and the large Dynamic Type overlay are verified only through the UI tests' frame assertion and previews. Check on device.
- `PhotoCreditView` still has no translations (the `%1$@` / `%2$@` ordering is kept literally by the replace-range code, which a translator could still break); English only is in scope.
- Snapshot images are macOS renderings and differ from iOS pixels; they guard layout only.
- `Gallery.xcodeproj/project.xcworkspace/xcshareddata/` (swiftpm resolution) appears untracked after an `xcodebuild` run; decide in M8 whether to commit or ignore it.

## Out of scope

Offline feed and its banner (M6, running in parallel: do not touch `OfflineFeed`, `FeedStore` or the offline banner), translations, iPad-specific layouts beyond the existing 3 columns, haptics.

## Rules for the implementer

- Strict TDD per ticket: write ONE test, run it and see it fail, write the minimal code to pass, repeat. Never write the whole test list first. Swift Testing (`@Test`, `#expect`, `@Suite(.trackingLeaks)` where a class is under test), `makeSUT` with `trackForMemoryLeaks`.
- Commands: `cd Gallery && swift test`; from the repo root `swift format lint -r Gallery App AppUITests` (fix with `swift format -i -r Gallery App AppUITests`). App build and UI tests: `xcodebuild … -project Gallery.xcodeproj -scheme GalleryApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath <your own scratch dir>`.
- No code comments anywhere. Swift 6 strict concurrency, `@Observable @MainActor` models, iOS 17 minimum; iOS 18 APIs only behind `#available`.
- `App/` and `AppUITests/` are synchronized folder groups. Never stage `project.pbxproj` or the scheme.
- Decisions go into `docs/decision-log.md` under `## M7 — Polish` (created in ticket 01), in the same commit as the code.
- One commit per ticket, conventional subject from the ticket, 2–4 line body, the ticket's `Status: done` in the same commit. Plain `git commit` (authored by the user's git config); never a `Co-Authored-By` or Claude attribution line.
- Do not edit `.scratch/roadmap.md`; the main session updates it after merging.
