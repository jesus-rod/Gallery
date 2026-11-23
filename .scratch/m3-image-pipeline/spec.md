# M3 — Image pipeline

Status: spec, seams to agree

## Goal

Grid cells show a BlurHash Preview at once, then fade in a Rendition fetched at the cell's exact pixel size. Images flow through our own `GalleryImageLoading` pipeline (ADR 0001): memory cache of decoded, downsampled images → disk cache of raw bytes → in-flight dedup → remote. Upcoming cells are prefetched; a cell scrolling away cancels its load without cancelling a load someone else shares. `-useStubs` serves bundled image data, so XCUITests never touch the network.

## Use cases

**Grid Rendition**
- Built from `raw`, keeping its existing query items (`ixid` etc.), adding `w` (points), `dpr` (screen scale), `q`, `fm=jpg`. Existing values for those keys are replaced, not duplicated.

**Show a cell's image**
- Happy: cell appears → Preview decoded from BlurHash (32×32, cached by hash) → Rendition loaded → image fades in over the Preview.
- No BlurHash: neutral fill until the Rendition arrives.
- Sad: load fails → Preview (or fill) stays; no error UI in the cell. Next appearance retries.
- Cell disappears before the load finishes → `.task(id:)` cancels its request.

**Load image data (remote)**
- 200 with non-empty body → data. Non-200, empty body or transport error → error. Cancellation propagates.

**Deduplicate in-flight loads**
- Two concurrent requests for the same URL → one upstream call, both get the result (or the error).
- One caller cancels while another waits → the shared upstream load keeps running; the cancelled caller gets `CancellationError`.
- All callers cancel → the upstream load is cancelled.
- After completion (success or failure) the URL is forgotten, so a later request goes upstream again.

**Disk cache (raw bytes)**
- Hit → data, no upstream call. Miss → upstream, then stored. Store failures are ignored (load still succeeds).
- Store lives in Caches; reading marks an entry as recently used.
- Eviction at launch, in the background: oldest-used entries removed until the total is at or under the byte budget (about 200 MB).

**Decode and downsample**
- Data + max pixel size → `CGImage` via ImageIO thumbnail, never larger than asked, orientation applied. Undecodable data → error. Runs off the main actor.

**Memory cache (decoded images)**
- Keyed by URL + max pixel size. Hit → no decode, no data load. Cost = width × height × 4 bytes; limit about 100 MB. `removeAll()` empties it (composition root calls it on memory warning). Failures are not cached.

**Prefetch**
- When item i appears, items i+1…i+k start loading at the current cell pixel size (k from configuration).
- A new window cancels prefetches that fell out of it. A cancelled prefetch never cancels a load a visible cell shares (dedup's job).

**Run on fixtures**
- `-useStubs` swaps the remote image fetch for one answering any `images.unsplash.com/fixture-*` URL with bundled image data.

## Seams under test

| Seam | Module | Observed through |
|---|---|---|
| `UnsplashRendition.gridURL(raw:pointWidth:scale:)` | Core | Returned URL query items |
| `RemoteImageDataLoader(fetch: (URL) async throws -> (Data, HTTPURLResponse))` | ImageLoading | Data or thrown error, given a stubbed fetch |
| `InFlightDedupImageDataLoader(decoratee:)` | ImageLoading | Upstream call count, results per caller, upstream cancellation, via a spy held by `Gate` |
| `FileImageDataStore(directory:)` | ImageLoading | `insert` / `retrieve` / `evict(toFit:)` on a temp directory |
| `DiskCachingImageDataLoader(decoratee:store:)` | ImageLoading | Data, upstream calls, store inserts, with an in-memory store spy |
| `DownsamplingImageLoader(dataLoader:)` | ImageLoading | `CGImage` dimensions for generated PNG data; error for garbage |
| `MemoryCachingImageLoader(decoratee:costLimit:)` | ImageLoading | Decoratee call count on repeat, after `removeAll()`, after a failure |
| `BlurHash.decode(_:width:height:)` and `PreviewCache` | ImageLoading | Image size, nil for invalid hashes, average colour of a known hash; decode count on repeat |
| `ImagePrefetcher(loader:distance:)` | ImageLoading | Which loads start and which get cancelled as the window moves |
| `PhotoImageModel` (one per cell) | UI | `state` goes preview → image; stays preview on failure; leak-checked |
| App end to end | App | XCUITest with `-useStubs`: cells show an image (accessibility value or identifier flips once loaded) |

Views (`PhotoCell`, fade) stay logic-free and are covered by `#Preview`s and the XCUITests. Every decorator gets a leak check.

## Shape (proposed)

```swift
// GalleryImageLoading
public protocol ImageDataLoader: Sendable {
    func loadImageData(from url: URL) async throws -> Data
}
public protocol ImageLoader: Sendable {
    func loadImage(from url: URL, maxPixelSize: Int) async throws -> CGImage
}
public protocol ImageDataStore: Sendable {
    func retrieve(for url: URL) async throws -> Data?
    func insert(_ data: Data, for url: URL) async throws
}
public struct ImagePipelineConfiguration: Sendable {
    public var memoryCostLimit: Int      // ~100 MB
    public var diskByteLimit: Int        // ~200 MB
    public var prefetchDistance: Int     // k
    public var previewSize: Int          // 32
    public var jpegQuality: Int          // q
    public static let `default`: Self
}

// Composition (app target), outermost first:
// MemoryCachingImageLoader
//   → DownsamplingImageLoader
//     → DiskCachingImageDataLoader(store: FileImageDataStore)
//       → InFlightDedupImageDataLoader
//         → RemoteImageDataLoader(fetch: image URLSession, urlCache = nil)
```

`RemoteImageDataLoader` takes a fetch closure because ImageLoading cannot see Core's `HTTPClient` (ADR 0002); the composition root adapts `URLSessionHTTPClient`. The memory cache sits above decoding, so the remote and disk layers only ever handle bytes.

In UI, `PhotoGrid` receives an `ImageLoader`, a `PreviewCache` and an `ImagePrefetcher`; each cell owns a `PhotoImageModel` driven by `.task(id: url)`. Load more stays on `.onAppear { Task {} }` (carried from M2); image loads use `.task(id:)` because cancellation is wanted.

## Out of scope

Full-screen `regular` Rendition (M5), Offline feed (M6), snapshot tests (M7), Instruments measurements of each layer (M8; the README reports them).

## Carried from M2

- Run the live feed once with a real key in `Config/Secrets.xcconfig`: ticket 12, manual.
- Mapper helper extraction: still not needed.
