# Decision log

Every notable decision, newest milestone last, with a one-line why. The big, hard-to-reverse ones have an ADR in `docs/adr/`. This log is also the outline for presenting the solution.

## Before M1 (grilling)

- Own image pipeline, no Nuke/Kingfisher, so every layer can be explained and measured. [ADR 0001](adr/0001-own-image-pipeline.md)
- SPM modules; Core and ImageLoading also build for macOS so `swift test` runs without a simulator, and the build itself blocks UIKit or SwiftUI from leaking in. [ADR 0002](adr/0002-spm-modules-testable-on-macos.md)
- Search on submit, because the budget is 50 requests an hour. [ADR 0003](adr/0003-search-on-submit.md)
- Offline feed as a versioned JSON store with no expiry. [ADR 0004](adr/0004-offline-feed-json-store-no-expiry.md)
- Fixed square cells in `LazyVGrid`, so layout stays cheap and every Rendition is requested at an exact pixel size. [ADR 0005](adr/0005-fixed-cell-lazyvgrid.md)

## M1 — Feed API and paging

- Mappers only translate; `PhotoStream` owns every stopping rule and dedups Photos by id.
- No `RemoteFeedLoader`: the composition root wires endpoint → client → mapper.
- 403 with `X-Ratelimit-Remaining: 0` maps to `rateLimited`, shown as its own state.

## M2 — Grid UI

- The view model depends on a `loadFeed` closure, not on `PhotoStream`: the narrowest dependency it needs.
- `LoadError` keeps Foundation and API errors out of the views.
- Load more runs from `.onAppear { Task {} }`, not `.task`, so a cell scrolling away never cancels a shared page load.
- Memory leak checks use a Swift Testing scoping trait (`.trackingLeaks`), because Swift Testing has no `addTeardownBlock`.

## M3 — Image pipeline

- Layer order, outermost first: memory cache (decoded) → downsampling → disk cache (bytes) → in-flight dedup → remote. Only the top layer handles pixels; everything below it moves bytes.
- In-flight dedup gives each caller its own continuation: a cancelled caller leaves at once, and the shared download is cancelled only when the last caller leaves. It's a lock-guarded class, not an actor. [ADR 0006](adr/0006-in-flight-dedup-with-per-caller-cancellation.md)
- `RemoteImageDataLoader` takes a fetch closure instead of `HTTPClient`, because ImageLoading can't import Core (ADR 0002). The composition root adapts `URLSessionHTTPClient`.
- Disk store file names are the SHA-256 of the URL (CryptoKit, a system framework with no UI). The last-used time is the file's modification date, so LRU eviction needs no index file. The clock is injected, so tests don't depend on real time.
- Store errors never fail a load: a failed read counts as a miss and a failed write is ignored.
- The grid Rendition sets only the width (`w`, plus `dpr`, `q` and `fm=jpg`), not a height or a crop, so M5 can show the cached grid image under the full-screen one.
- Decoding uses an ImageIO thumbnail (`CreateThumbnailFromImageAlways`, `ShouldCacheImmediately`, no source cache), never `UIImage(data:)`. Only the downsampled bitmap is ever in memory, and it's decoded inside the loader, not on the main thread during rendering. The loader is a nonisolated `async` function, so under the Swift 6.0 language mode it runs off the main actor.
- The memory cache holds decoded `CGImage`s in an `NSCache` keyed by URL and max pixel size, with each image's cost set to its real bitmap size (`bytesPerRow × height`). `NSCache` evicts under memory pressure, and the app also calls `removeAll()` on a memory warning. Failures are never cached.
- Our own BlurHash decoder (about 100 lines), with no dependency. Previews are decoded at 32×32 and the cell scales them up, which keeps a decode around a tenth of a millisecond. Cosines are precomputed per axis, and `PreviewCache` decodes each hash only once. Decoding is cheap enough to run synchronously, so a cell has its Preview on its very first frame.
- Prefetching works as a sliding window: each call names the Renditions that should be warm, and anything that fell out of the window is cancelled. The prefetcher holds no other state. A cancelled prefetch only cancels its own wait, thanks to dedup (ADR 0006), so a visible cell sharing the URL keeps loading. Prefetches go through the full pipeline, so they warm both the memory and disk caches.
- Leak checks in async tests allow a one-second grace period, because cancelled tasks release their captures shortly after the test body returns. A real retain cycle still fails the test.
- The grid Rendition is sized so its *shorter* side covers the square cell: landscape Photos get a wider `w`, portrait Photos keep `w` equal to the cell side, and the downsampling target is the matching longest side. With `w` equal to the cell side, a landscape image would be upscaled and look blurry. The ratio is capped at 3:1, so a panorama costs at most three times the pixels of a square cell.
- GalleryUI depends on a `PhotoImages` value of closures that it defines itself, not on the pipeline types. The UI decides *when* images are needed (on appear, the window ahead); the composition root decides *how* they're fetched (Rendition URL, caches). It's the same narrow-dependency move as `loadFeed` in M2.
- Each cell owns a small `@Observable` `PhotoImageModel` (Preview → image, kept on failure) driven by `.task(id: size)`, so a cell scrolling away cancels its own load. Load more stays on `.onAppear { Task {} }`.
- The pipeline is composed in the app target (`ImagePipeline`), with every budget in one `ImagePipelineConfiguration`. Disk eviction runs at launch on a background-priority task; memory warnings empty the memory cache.
- `-useStubs` also stubs image downloads (four bundled gradient JPEGs), so the XCUITests never touch the network.

## M4 — Search

- The paging state machine moved into an internal `StreamPager`, so the Editorial feed and each Query's Search results run the same tested logic. It is tested through `GalleryViewModel` only.
- The view model takes a `search: (String) async throws -> Paginated<Photo>` closure next to `loadFeed`; the composition root builds a new `PhotoStream` with `SearchPhotosMapper` per Query.
- Each Query gets its own `StreamPager`; Search results reuse `StreamState`, and empty results are `.loaded(photos: [], footer: .end)`.
- The Query is trimmed; an empty Query, or the Query already shown, sends no request (Request budget).
