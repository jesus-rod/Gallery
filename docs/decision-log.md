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
- A new Query cancels the previous search's `Task` (the cancellation reaches `URLSession` through `PhotoStream`), and a late result can never show because it lands on the previous Query's pager, which nothing references any more.
- Cancelling search only drops the search pager; the feed's pager, Photos and in-flight load more are untouched, so going back costs no request.
- The feed view stays in a `ZStack` under Search results, hidden with opacity, hit testing and accessibility off, so its scroll position survives a search without storing it by hand.
- Clearing the search field (or Cancel, which clears it) returns to the feed; the search field is always visible (`navigationBarDrawer(displayMode: .always)`).
- Each Query's grid gets `.id(query)`, so new results start at the top.
- `-useStubs` also answers search: `search-<query>-page-N.json` for "cats" (two Pages, `total_pages: 2`), zero results for any other Query, so the XCUITests stay offline.

## M5 — Full-screen view

- The full-screen Rendition is sized from `raw` to the screen (aspect fit × display scale), replacing the earlier plan to use `regular`: `regular` is 1080 px wide, softer than an iPhone Pro Max (1320 px) or any iPad, and too big for a landscape Photo on a small phone. It reuses the grid's URL builder, renamed `sizedURL`.
- `Photo` is `Hashable` so it can be a navigation value; it is still not `Codable`.
- Links to the Photographer and to Unsplash carry `utm_source=gallery_ios&utm_medium=referral`, as the API guidelines require. `UnsplashAttribution` builds them in Core; the app name comes from the composition root.
- The Full-screen view asks for the grid image (a memory-cache hit, since the cell just showed it) and the full-screen Rendition at the same time, and never steps down: Preview → grid image → full image. A failed full image leaves the grid image; there is no error screen for it.
- The full-screen Rendition goes through the same pipeline and memory cache as the grid, with its own quality setting (80, grid 75), so reopening a Photo is instant.
- Zoom and pan maths live in a pure `ZoomTransform` value, tested without views; gestures only feed it numbers. 1× to 4×, double tap toggles 2.5× towards the tapped point, and the image edges never come inside the screen edges.
- Opening a Photo pushes a `FullScreenRoute` on the existing `NavigationStack`, so the grids and their scroll positions stay alive underneath. The cell opens it with a tap gesture and a default accessibility action instead of a `NavigationLink`; both would make the cell a button for accessibility, so the cell removes `.isButton` and stays an image.
- iOS 18+ zooms from the cell (`matchedTransitionSource` / `.zoom`); iOS 17 uses the standard push, because `NavigationStack` has no cross-fade push and faking one would mean presenting over the stack.
- The transition source ID includes the Stream, because the same Photo can sit in the hidden feed and in Search results at once.
- The Full-screen image frame is the Photo's aspect ratio fitted to the screen (`ContentFit`), and every image fills that frame, so the 32 × 32 Preview and the grid image (cropped at 3:1 for very tall portraits) keep the Photo's shape until the full image fades in.
- Our own drag dismisses on every iOS version: drag down at 1× slides the Photo and fades the background, a zoomed Photo pans instead. The iOS 18+ system zoom-dismiss never fired, because our full-screen `DragGesture` takes the touch first; checked on device, where pinch, pan and drag all behave.
- The gestures sit on a layer under the overlay, not on the whole view, so the Close button and the credit links get their taps. Close is a 44 pt circle on a dark fill, so it shows on light Photos.
- A Close button and the VoiceOver escape gesture close the view, because drag down is neither discoverable nor available to VoiceOver.

## Review fixes (M3, M4)

- Each `StreamPager` owns its in-flight request and can cancel it. A new Query or Cancel cancels every request of the old search (first Page, load more, retry), not just its first Page, so an abandoned search stops spending the Request budget.
- Re-submitting the shown Query is still a no-op, except after its first Page failed: then it searches again, like Retry.
- Image models do no work in `init`: SwiftUI rebuilds a view's `State(initialValue:)` argument on every parent redraw and keeps only the first, so the Preview is looked up lazily on first read and memoized.
- The Preview stays underneath and the image fades in on top, instead of cross-fading the two, which showed the grey cell fill mid-fade.
- Portrait Photos taller than 3:1 get a CDN centre crop at 3:1 in the grid (`h`, `fit=crop`), so they fill the cell at full sharpness with bounded memory. The earlier rule capped the decode size too, which made them narrower than the cell. The full-screen Rendition never crops.
- Updating a cached file's last-used date is best effort: if it fails, the read still counts as a hit.
- One XCUITest per user journey (feed, search, full screen), with each step asserted. Details live in unit tests, because every XCUITest relaunches the app and costs seconds. The six M2–M4 UI tests became two.

## M6 — Offline feed

- The Offline feed is one versioned JSON file (`version: 1`) read and written whole by an actor; an unknown version reads as empty rather than failing, so a future format change just starts fresh.
- It lives in Application Support, not Caches, so the system doesn't purge it exactly when the user is offline.
- Saving is a decorator around the feed's first-Page closure in Core (`OfflineFeed.saving`): every loaded Page re-saves the first 300 Photos, so the Offline feed is always the latest feed prefix; a save failure never breaks browsing.
- The view model falls back to the Offline feed on any first-Page error, not only offline, because a rate-limited or failing API also leaves nothing to show; `offlineFeedReason` keeps the error so the banner can say why.
- The Offline feed has no load more: paging needs the network, and the saved Photos are a prefix of the feed.
- The fallback lives in `StreamPager` (one place, used by first load, retry and refresh); Search pagers get no offline closure, so Search results are never replaced by saved Photos.
- The Offline banner is persistent (not auto-dismissed) and sits in a top safe-area inset of the feed grid, so it pushes Photos down instead of covering them and hides with the feed during search; the refresh error banner stays an overlay above it.
- `-stubOffline` and `-resetOfflineFeed` launch arguments let the XCUITests drive the offline path with a store separate from the real one (`OfflineFeed-stubs` in the temporary directory); both live inside `#if DEBUG`.
- The offline XCUITest checks that a failed pull to refresh keeps the saved Photos and the Offline banner, not the brief refresh error: XCUITest waits for the app to be idle, and the app is not idle while that banner shows, so the banner is gone before the test can query it. The unit tests cover the error.

## M7 — Polish

- A 401 gets its own state ("Access key not accepted"), because a wrong key is the most likely first-run failure for someone setting the project up; the message names the config file.
- Both mappers share one `requireDecodable` check (rate limit, 401, require 200, decode or `invalidData`), closing the duplication noted in M1.
- Search results get pull to refresh, sharing the feed's brief refresh error, which now shows over Search results too. A refresh that finishes after its Query was replaced or cancelled is ignored, so it cannot show a stale error.
- The hidden feed may still finish an in-flight load more while searching: accepted, it costs at most one request the user already triggered.
- Images already in the memory cache are read synchronously (`NSCache` is thread safe) through a `PhotoImages.cachedImage` closure, so a cell scrolled back into view or a reopened Photo shows its image on the first frame, with no Preview and no fade.
- The cell decides "no fade" from the model's memoized first lookup (`wasCachedOnAppear`) rather than a view flag set after appearing, which would race the first frame; `PhotoImageModel` now takes its grid size at init so that lookup is possible.
- Accessibility frames come from the sized shape, not the overflowing images, so VoiceOver's focus box matches what is on screen: the cell's accessibility element is its square, and the full-screen element is a clear frame of the fitted size, with the images in a hidden overlay.
- Reduce Motion removes the image fades and the spring back after an abandoned drag; the navigation zoom stays, since the system already adapts it. The overlay toggle was never animated.
- The full-screen overlay is split into a Close layer and a Caption layer around the gesture layer (raised with `zIndex`), so VoiceOver reads Close, image, Caption, credit by tree order. At large Dynamic Type sizes the Caption block scrolls inside 40% of the screen height (`ViewThatFits`), and the credit never truncates.
- The Close layer is `.accessibilityElement(children: .contain)`: a full-screen layer holding a single Button otherwise merged into it and reported the whole screen as its frame, so the UI test tapped the screen centre instead of the button.
- Snapshot tests (swift-snapshot-testing, test-only) render on macOS inside `swift test`, light and dark at a fixed size: fast and simulator-free, guarding layout regressions rather than exact iOS pixels. The hosted views get an explicit `windowBackgroundColor` background, because an off-screen host has none and dark-mode text would render white on white.

## M8 — Review sweep

- The refresh error sits in a top safe-area inset of the grids, not an overlay: the grids scroll under the navigation bar, so a top overlay hid the banner behind the title and search field. It stacks above the Offline banner.
- A refresh now runs as the pager's one in-flight request: it cancels a load more still running (so both are never sent) and can itself be cancelled, so a new Query or Cancel also stops a Search refresh. If it fails after cancelling a load more, the footer returns to idle so paging resumes.
- Switching between the feed and Search results cross-fades over 0.2 s (none with Reduce Motion), for the brief's seamless transition; the feed keeps its scroll position underneath as before.
- Accepted: after a cell changes size (rotation, 2 → 3 columns), it shows its previous image scaled until the new Rendition loads.
- Every image layer (Preview, grid image, full-screen image) fills a `Color.clear` of exactly the frame (`Image.filling()`). Inside one `ZStack`, a `scaledToFill` Preview and image of different aspect ratios sized against each other and pushed the image down, leaving a band of Preview above it in the grid and full screen.
