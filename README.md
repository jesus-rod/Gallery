# Gallery

## Overview

An Unsplash photo browser in SwiftUI for iOS 17+, on iPhone and iPad:

- **Grid**: a stretchy hero of the first Editorial photo, then square cells (2 columns compact, 3 regular), each with its caption (alt description → description → "Untitled photo"), and endless scroll.
- **Search**: the same grid and endless scroll for a query (field at the bottom on iOS 26), cross-fading over the feed, which keeps its scroll position underneath.
- **Full screen**: opens with a zoom from the cell on iOS 18+ (standard push on iOS 17), glowing with the photo's own colours. Swipe between photos with parallax, pinch and double-tap zoom, pan, swipe up for Info, Share, drag down or Back to return, Photographer credit with Unsplash referral links.
- **Own image pipeline**: memory and disk caches, in-flight dedup, prefetch and cancellation, downsampling off the main thread, BlurHash placeholders, and a rendition sized to each cell and each screen.
- **Offline feed**: the last ~300 feed photos are saved and shown, with a banner, when the network fails.
- **States**: skeleton, paging footer with retry, full-screen errors, a friendly rate-limit message, invalid access key, empty search, pull to refresh, Dynamic Type, VoiceOver, Reduce Motion, dark mode.

## Setup

Requirements: Xcode 16 or later, iOS 17 or later.

1. Create an Unsplash app at <https://unsplash.com/oauth/applications> and copy its **Access Key**.
2. Create the local secrets file, which is gitignored:
   ```sh
   cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
   ```
3. Replace `your-unsplash-access-key` in `Config/Secrets.xcconfig` with your key, without quotes: xcconfig keeps quotes as part of the value, and Unsplash then rejects the key with a 401.
4. Open `Gallery.xcodeproj` and run the `GalleryApp` scheme.

No key? Add `-useStubs` to the scheme's launch arguments to run on bundled fixtures (feed, the "cats" search, images). `-stubOffline` adds a simulated offline network.

Run the logic tests without a simulator:

```sh
cd Gallery && swift test
```

## Design

The structure follows Apple Photos on iOS 26, with three additions that cost no extra requests:

- **Ambient glow**: the full screen glows with the photo's colours. The glow is its BlurHash Preview, already decoded at 32 × 32 for the placeholder, scaled up smoothly and dimmed behind the photo. It needs no download, decode or blur filter of its own: a live blur over the full screen showed up as GPU hitches in Instruments, and the upscaled BlurHash looks almost the same. It fades to black when the controls hide, and Reduce Transparency turns it off.
- **Swipe between photos**: full screen pages through the Stream it was opened from (feed or Search results), with parallax, and loads more near the end through the grid's own paging path (ADR 0007). Only the current photo and its neighbours hold full-size images.
- **Stretchy hero**: the feed opens with its first photo full width. Pulling down stretches it from the top, scrolling moves it at half speed. Both are computed in `.visualEffect`, so scrolling writes no state.
- **Glass chrome**: Back, Share and Info are glass circles (material before iOS 26). The title holds the caption and "Photo by Name", so the photo stays unobstructed and the credit stays on screen. Info opens a sheet with the full credit, description and size.

| Feed with hero | Full screen | Ambient glow |
|---|---|---|
| <img src="docs/images/feed.jpg" width="250" alt="Feed with the stretchy hero and the grid"> | <img src="docs/images/full-screen.jpg" width="250" alt="Full-screen photo with glass controls"> | <img src="docs/images/full-screen-glow.jpg" width="250" alt="Full-screen photo glowing with its own colours"> |

<img src="docs/images/landscape.jpg" width="770" alt="Full-screen photo in landscape">

On iPhone Duo, folded and unfolded:

<img src="docs/images/duo-folded.jpg" height="380" alt="Feed on iPhone Duo, folded"> <img src="docs/images/duo-unfolded.jpg" height="380" alt="Full-screen photo on iPhone Duo, unfolded">

## Architecture

```mermaid
flowchart LR
  App["GalleryApp<br/>(composition root)"] --> UI["GalleryUI<br/>SwiftUI views, view models"]
  App --> Core["GalleryCore<br/>domain, API, paging, offline store"]
  App --> Images["GalleryImageLoading<br/>image pipeline"]
  UI --> Core
```

Three SPM modules and an app target. **GalleryCore** (Foundation only) holds the domain (`Photo`, `PhotoStream`, `Paginated`), the Unsplash endpoints, mappers and renditions, the HTTP client and the Offline feed store. **GalleryImageLoading** (Foundation, ImageIO, CoreGraphics) is the image pipeline and knows nothing about photos or Unsplash. **GalleryUI** depends only on Core and receives everything else as closures. Only the composition root (`App/GalleryApp.swift`, `App/ImagePipeline.swift`) sees all three and wires concrete types together. Core and ImageLoading also build for macOS, so `swift test` runs their tests in about a second (ADR 0002).

**Image pipeline**: decorators around one protocol, outermost first. The UI only sees `PhotoImages` closures.

```mermaid
classDiagram
  direction LR
  class PhotoImages {
    +preview()
    +cachedImage()
    +image()
    +fullScreenImage()
    +prefetch()
  }
  class ImageLoader {
    <<protocol>>
  }
  class ImageDataLoader {
    <<protocol>>
  }
  class ImageDataStore {
    <<protocol>>
  }
  ImagePipeline ..> PhotoImages : builds closures
  ImagePipeline --> MemoryCachingImageLoader
  ImagePipeline --> ImagePrefetcher
  ImagePipeline --> PreviewCache
  ImageLoader <|.. MemoryCachingImageLoader
  ImageLoader <|.. DownsamplingImageLoader
  MemoryCachingImageLoader --> DownsamplingImageLoader : decoratee
  ImagePrefetcher --> MemoryCachingImageLoader
  DownsamplingImageLoader --> DiskCachingImageDataLoader
  ImageDataLoader <|.. DiskCachingImageDataLoader
  ImageDataLoader <|.. InFlightDedupImageDataLoader
  ImageDataLoader <|.. RemoteImageDataLoader
  DiskCachingImageDataLoader --> InFlightDedupImageDataLoader : decoratee
  DiskCachingImageDataLoader --> ImageDataStore
  ImageDataStore <|.. FileImageDataStore
  InFlightDedupImageDataLoader --> RemoteImageDataLoader : decoratee
```

**Feed, search and offline**: the view model depends on closures, not on Core types, and the composition root builds them.

```mermaid
classDiagram
  direction LR
  class GalleryViewModel {
    +loadFeed()
    +loadOfflineFeed()
    +search(query)
  }
  class FeedStore {
    <<protocol>>
  }
  class HTTPClient {
    <<protocol>>
  }
  GalleryViewModel --> StreamPager
  CompositionRoot ..> GalleryViewModel : injects closures
  CompositionRoot ..> OfflineFeed : saving(loadFeed, store)
  CompositionRoot ..> PhotoStream : feed and per-Query search
  PhotoStream ..> UnsplashEndpoint
  PhotoStream ..> EditorialPhotosMapper
  PhotoStream ..> SearchPhotosMapper
  OfflineFeed ..> FeedStore
  FeedStore <|.. CodableFeedStore
  HTTPClient <|.. AuthorizingHTTPClient
  HTTPClient <|.. URLSessionHTTPClient
  AuthorizingHTTPClient --> URLSessionHTTPClient : decoratee
```

Arrows follow the dependency-diagram notation: `<|..` conforms, `-->` has a (strong, injected), `..>` uses. Closure dependencies are drawn as "uses" with a label, because the code injects closures at these seams.

- **Boundaries by closure.** `GalleryViewModel` takes `loadFeed`, `loadOfflineFeed` and `search` closures, and views take `PhotoImages`. UI tests and previews swap them freely, and the UI never sees URLs, caches or Unsplash.
- **Mappers only translate.** `PhotoStream` owns every paging rule: stop on `total_pages` or an empty page, drop duplicate ids. Mappers turn a response into a `PhotoPage` or a typed error (rate limited, invalid key, invalid data).
- **Decorators, not a god object.** Memory cache → downsampling → disk cache → dedup → network, each one small and unit tested on its own (ADR 0001, 0006).
- **Styles in one place.** Spacing, hit target, scrim and control opacities, fade timings, the banner chip and the caption scrim live in `GalleryUI/DesignSystem/`. They move into their own module once a second feature or app needs them; with one feature, a module would be speculative.
- **Storage models separate from the domain.** `Photo` is not `Codable`. The Offline feed saves private `Local*` mirrors in a versioned JSON file (ADR 0004).

## Technical choices

| Decision | Why | Record |
|---|---|---|
| Own image pipeline, no library | The brief rewards it, and each layer (cache, dedup, prefetch, downsampling) can be measured in Instruments | ADR 0001 |
| SPM modules, logic also on macOS | Enforced boundaries; logic tests run in `swift test` with no simulator | ADR 0002 |
| Search on submit, not as you type | 50 requests/hour: typing "mountain" would spend 8 | ADR 0003 |
| Offline feed: JSON file, network first, no expiry | A few hundred records read and written whole; shown only when the alternative is an empty screen | ADR 0004 |
| Fixed square cells in `LazyVGrid` | Known pixel size per cell, so each rendition is requested at exactly that size | ADR 0005 |
| In-flight dedup with per-caller cancellation | A cancelled prefetch must not cancel the visible cell's shared load | ADR 0006 |
| Full screen pages through the Stream, not one Photo | Swiping is the first thing people try in a photo viewer; reusing the Stream keeps paging rules and the request budget in one place | ADR 0007 |
| Renditions sized from `raw` (`w`, `dpr`, `q`, `fm=jpg`), keeping the URL's existing query items | `regular` (1080 px) is too soft on large phones and iPads and too big for small cells | decision log, M3/M5 |
| One request in flight per Stream; a new Query, Cancel or refresh cancels the old request | Every request counts against the hourly budget | decision log, review fixes and M8 |

Every decision, big or small, is listed in [`docs/decision-log.md`](docs/decision-log.md).

## Performance

- **Right-sized images**: each cell asks for its exact pixel size (`w` × `dpr`), decoded with ImageIO downsampling off the main thread. Full screen asks for the screen's fitted size. Very tall portraits are cropped at 3:1 by the CDN, so they fill the cell sharply with bounded memory.
- **Caches**: decoded images in an `NSCache` limited to about 100 MB by pixel cost and cleared on memory warning. Raw bytes on disk, about 200 MB with LRU eviction in the background at launch. BlurHash placeholders decoded at 32 × 32 and cached by hash.
- **No duplicated work**: one in-flight request per URL, shared by every caller (cell, prefetch, full screen). Prefetch covers the next 9 photos. Cancelling a prefetch never cancels a visible cell.
- **Minimal SwiftUI updates**: `@Observable` models scoped per cell. Images already in memory show on the first frame, with no placeholder or fade. The full-screen overlay is kept out of per-frame gesture updates.

### Measured with Instruments

On an iPhone 15 Plus (60 Hz, iOS 27), Release build, live key. Run A used the SwiftUI template (SwiftUI, Hangs, Animation Hitches, Time Profiler); Run B used Allocations. Apple's hitch guidance: under 5 ms/s is good, 5–10 noticeable, over 10 critical.

| Scenario | Before | After |
|---|---|---|
| Hero pull and feed scroll | 0 hitches, 10% main thread | unchanged |
| Grid scroll, ~300 images | 6.5 ms/s hitch time, 13% main thread, all downsampling off the main thread | unchanged |
| Full-screen swipe, ~50 photos | **20.7 ms/s**, 19 GPU-bound hitches, a 159 ms hang | **8.1 ms/s**, 1 GPU-bound hitch, no hang |
| Dismiss drag | 3.4 ms/s | unchanged |
| Memory after scrolling ~500 images | **1.17 GB** still in memory, 1.135 GB of it decoded grid images | _re-record pending_ |

Three problems found, three fixes:

1. **The full-screen pager rebuilt itself on every update** (Time Profiler: `FullScreenPhotoView.body` on every page change and every frame of the dismiss drag, copying the whole Stream each time). A small `PagerWindow` value now works out the current photo and the neighbours that load the full image once per update, and the drag offset moved to its own observable model that only the views that move read. Result: 15.9 ms/s, no mid-swipe hang, and the body no longer shows in the profile.
2. **The ambient glow was a radius-60 blur over the whole screen**, doubled during the page cross-fade (Animation Hitches: GPU-bound frames with up to 31 offscreen passes). A BlurHash is already smooth, so the glow is now the 32 × 32 Preview scaled up and dimmed, with no filter. Result: 8.1 ms/s, GPU hitches 19 → 1.
3. **Grid cells kept their decoded images after scrolling away** (Allocations: 438 live images, far beyond the 100 MB cache). SwiftUI keeps a lazy grid cell's state after it leaves the screen, so each cell's image model held on to its image. Cells and the hero now release the image on `onDisappear` and read it back from the memory or disk cache when they return.

How the fixes were checked: each one started from a trace, not a guess (a first guess for problem 3, that full-screen images were being kept, was wrong and reverted). The logic changes were built test first: `PagerWindowTests` for the pager window, and two `PhotoImageModelTests` for releasing and re-reading the cache. Then the same scenario was recorded again on the same phone with the same build settings, and the numbers above come from those recordings, read with `xctrace export`. The full method and every run are in [`.scratch/m9-photos-polish/instruments-run-a.md`](.scratch/m9-photos-polish/instruments-run-a.md).

## Testing

- **278 unit tests** in Swift Testing, in three targets: Core 73, ImageLoading 50, UI 155, including 14 snapshot tests of the cell and the empty and error states in light and dark. Every class under test goes through `makeSUT` with leak tracking. Logic was built test first, one test at a time.
- **4 XCUITests**, one per user journey: browse and page the feed, search and clear back to the feed, open a photo full screen and close it, launch offline with a saved feed. They run on bundled fixtures (`-useStubs`), with no network and no key.
- **CI** runs `swift test`, then the UI tests on a simulator.

## Trade-offs and improvements

- **The client-side key ships in the app bundle.** That's fine for a demo; production would put a server proxy in front of Unsplash.
- **iOS 17 gets a standard push**, not the zoom transition: `NavigationStack` has no zoom on iOS 17, and faking one would mean presenting over the stack.
- **The Offline banner hides on the next successful load**, not when the network comes back (no reachability monitoring).
- **Snapshot tests render on macOS**: they guard layout, not exact iOS pixels.
- **Not built**: a sharper rendition when zoomed past 1×, translations (the String Catalog is English only).

## AI usage

Built with Claude Code as a pair. The whole trail is in the repo:

- [`.scratch/`](.scratch/): `roadmap.md`, then one folder per milestone with its spec and tickets, including review notes and every deviation an agent made.
- [`docs/decision-log.md`](docs/decision-log.md) and [`docs/adr/`](docs/adr/): every decision as it was made.

How it was used: grilling the plan into a domain glossary (`CONTEXT.md`), ADRs and milestone specs; agents implementing tickets test first, one test at a time, later two milestones in parallel git worktrees; and review passes (standards, spec, security, SwiftUI performance) whose fixes are separate commits. I reviewed and verified every agent batch (tests, lint, authorship) before merging. Device checks, Instruments and the final review are mine.
