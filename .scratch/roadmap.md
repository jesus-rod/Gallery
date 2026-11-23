# Roadmap

Entry point for a fresh session. Read this, then `CONTEXT.md`, `docs/adr/`, and the current milestone's `spec.md` and `issues/`. A ticket's `Status:` line says where work stands; `git log --oneline` shows what is committed.

## Working loop

1. Milestone starts: write `.scratch/<milestone>/spec.md` (use cases, seams under test) and `issues/NN-<slug>.md` tickets.
2. Agree the seams with the user before writing any test.
3. Per ticket, `/tdd`: one failing test, minimal code to green, repeat. Swift Testing. Run `swift test` in `Gallery/` and `swift format lint -r Gallery` from the repo root.
4. Ticket green: set `Status: done`, propose commits (subject + body), commit only after the user approves. Authored by the user, never a co-author line.
5. Quick essential-feed review per milestone. No code comments anywhere.

## Milestones

| # | Milestone | State |
|---|---|---|
| M0 | Scaffold: package, app target, key config, CI, README skeleton | done |
| M1 | Feed API + paging (`.scratch/m1-feed-api/`) | in progress |
| M2 | Grid UI with fixtures, `-useStubs` launch path, XCUITest target | |
| M3 | Image pipeline | |
| M4 | Search | |
| M5 | Full-screen view + transition | |
| M6 | Offline feed | |
| M7 | Polish: UX states, accessibility | |
| M8 | Review sweep, Instruments, dependency diagram, README, Loom | |

## Settled decisions

Recorded in ADRs: own image pipeline (0001), SPM modules testable on macOS (0002), search on submit (0003), offline feed JSON store with no expiry (0004), fixed square cells in `LazyVGrid` (0005).

**Stack**: SwiftUI, Swift Testing (XCUITest only for UI tests), Swift 6 strict concurrency, `@Observable` `@MainActor` view models, iOS 17 minimum, iPhone and iPad, all orientations.

**Modules**: `GalleryCore` (Foundation only), `GalleryImageLoading` (Foundation, ImageIO, CoreGraphics), `GalleryUI` (SwiftUI), app target `GalleryApp` as composition root. Core and ImageLoading never import each other.

**Core / paging**
- Mappers are public caseless enums returning `PhotoPage(photos, totalPages: Int?)`; Editorial gives `nil`. Mappers only translate.
- `PhotoStream` builds `Paginated<Photo>` from `(Int) async throws -> PhotoPage` and owns every stopping rule: stop when page reaches `totalPages` or a Page is empty; drop Photos whose id is already in the Stream.
- No `RemoteFeedLoader`: the composition root wires endpoint → client → mapper.
- `per_page=30`. Load more about 6 items before the end. One request in flight, guarded in the view model.
- 403 with `X-Ratelimit-Remaining: 0` maps to `rateLimited`, shown as its own friendly state.

**Networking**: two sessions. API session behind `AuthorizingHTTPClient` (adds `Authorization: Client-ID`, `Accept-Version: v1`); image session with `urlCache = nil`. The key never appears in logs or errors.

**Image pipeline**: `ImageDataLoader` decorators, outermost first: memory cache (decoded, downsampled images, `NSCache` about 100 MB by pixel cost, cleared on memory warning) → disk cache (raw bytes in Caches, about 200 MB, LRU eviction at launch in background) → in-flight dedup actor → remote. ImageIO downsampling off the main thread. Prefetch items n+1…n+k on appear. `.task(id:)` cancels; a cancelled prefetch must not cancel a shared load. Budgets live in one `ImagePipelineConfiguration`. Own BlurHash decoder at 32×32, cached by hash. Measure each layer in Instruments.

**Renditions**: grid builds from `raw` with `w`, `dpr`, `q`, `fm=jpg` for the exact cell pixel size, keeping existing query items. Full screen uses `regular`, with the cached grid image underneath.

**Domain**: `Photo` is not Codable. Caption rule (alt description → description → localized "Untitled photo") is a pure presentation function in UI. Photographer credit is required by Unsplash guidelines.

**UI**
- One `GalleryViewModel` holding two independent paging states, Editorial feed and Search results. Cancelling search restores the feed with no request and the same scroll position; a new Query cancels the old one.
- One shared `PhotoGrid` view. 2 columns compact, 3 regular.
- States: skeleton first load; spinner footer while paging; inline retry footer on page failure; full-screen error with retry on first-page failure; rate-limited message; empty search with the Query echoed; pull to refresh on the feed; image fade-in over the Preview.
- Accessibility: captions as VoiceOver labels, Dynamic Type, dark mode, English String Catalog.
- Full screen: push in the `NavigationStack`, nav bar hidden, `.navigationTransition(.zoom)` on iOS 18+, cross-fade on iOS 17. Pinch and double-tap zoom, drag down to dismiss, overlay with Caption and Photographer.

**Offline (M6)**: up to about 300 Editorial feed Photos in a versioned JSON `FeedStore`; network first, fall back to the store, save each loaded page. No expiry; a successful first Page replaces it. Search results never stored. Offline banner; pull to refresh while offline keeps the Offline feed and shows a brief error. The same Photo in both Streams shares cached Renditions; dedup is per Stream.

**Dev and tests**: `-useStubs` launch argument swaps in a `StubHTTPClient` with bundled JSON fixtures, used by XCUITests. 2–3 XCUITest acceptance tests, snapshot tests (swift-snapshot-testing, test-only) for cell and empty/error states.

**Reviews before shipping**: `/code-review`, `/security-review`, performance (`swiftui-pro` + user-recorded Instruments: Time Profiler, Allocations, SwiftUI, after ~500 images), UX pass, `/ios-skills:essential-feed diagram` for the README, pre-submit sweep.

**Repo rules**: no company names in any file or the repo name; repo stays private until submission; `.scratch/` is committed; README "AI usage" section points to it.
