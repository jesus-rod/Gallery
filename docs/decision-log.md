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
