# Roadmap

Entry point for a fresh session. Read this, then `CONTEXT.md`, `docs/adr/`, and the current milestone's `spec.md` and `issues/`. A ticket's `Status:` line says where work stands; `git log --oneline` shows what is committed.

## Working loop

1. Milestone starts: write `.scratch/<milestone>/spec.md` (use cases, seams under test) and `issues/NN-<slug>.md` tickets.
2. Agree the seams with the user before writing any test.
3. Per ticket, `/tdd`: one failing test, minimal code to green, repeat. Swift Testing. Run `swift test` in `Gallery/` and `swift format lint -r Gallery` from the repo root.
4. Ticket green: set `Status: done`, propose commits (subject + body), commit only after the user approves. Authored by the user, never a co-author line.
5. Quick essential-feed review per milestone. No code comments anywhere.
6. Every notable decision goes into `docs/decision-log.md` in the same commit as the code; big or hard-to-reverse ones also get an ADR. The log feeds the presentation.

## Milestones

| # | Milestone | State |
|---|---|---|
| M0 | Scaffold: package, app target, key config, CI, README skeleton | done |
| M1 | Feed API + paging (`.scratch/m1-feed-api/`) | done |
| M2 | Grid UI with fixtures, `-useStubs` launch path, XCUITest target (`.scratch/m2-grid-ui/`) | done |
| M3 | Image pipeline (`.scratch/m3-image-pipeline/`) | done (ticket 12, the live-key run, is waiting on the user) |
| M4 | Search (`.scratch/m4-search/`) | done (`.scratch/m4-search/`) |
| M5 | Full-screen view + transition (`.scratch/m5-full-screen/`) | done (device check and Instruments in ticket 07's human part) |
| M6 | Offline feed (`.scratch/m6-offline-feed/`) | done, merged |
| M7 | Polish: UX states, accessibility (`.scratch/m7-polish/`) | done, merged (VoiceOver and Accessibility Inspector check left for M8) |
| M8 | Review sweep, Instruments, dependency diagram, README, Loom (`.scratch/m8-ship/`) | tickets 01–06 done; **next: ticket 08** (snapshot matrix on the iOS simulator, ready-for-agent, not started); ticket 07 (Instruments, VoiceOver, live key, device, Loom, submission) is the user's |
| M9 | Photos-style polish with ambient glow, swipe between photos, stretchy hero (`.scratch/m9-photos-polish/`), done before M8 ticket 08 so snapshots record the final look | tickets 01–07 done; journeys, app icon, README Design section and screenshots pushed; **next: ticket 08** (user records Instruments, agent writes the numbers up) |

## Resume here (2026-11-23, late night)

- **M9 tickets 01–07 are done and pushed**, plus `6043016` (README Design section, ADR 0007 row, test counts), `037ae1a` (XCUITest journeys for the new look), `7e612bc` (app icon), `8a4e2db` and `a388fdb` (README screenshots taken with a live key, in `docs/images/`, including iPhone Duo) and `b2edc3e` (edge-to-edge feed with a floating title like Photos).
- **Edge-to-edge feed (`b2edc3e`)**: the grid ignores the side safe area (Duo strip, landscape) and, with a hero, the top one; a custom large white "Gallery" toolbar item stays pinned while the hero shows; soft top scroll edge. User approved the look as is. Accepted gap: on iOS 27 the soft edge is tinted light and the status bar stays dark (iOS 27 only applies the dark bar scheme with a "visible" bar background, which turns the edge hard). If the user revisits it, the fallback is our own dark gradient behind the title.
- **Not rerun after `b2edc3e`'s last two tweaks** (bar background removed, soft edge added): the XCUITest journeys (they passed just before) and lint/`swift test` (passed just before). Run them at the start of the next session.
- **README screenshots are stale**: `docs/images/feed.jpg`, `duo-folded.jpg` and `duo-unfolded.jpg` show the old white header and the Duo side strip. Ask the user for new ones (they take them with a live key on their own simulator and send Desktop paths); convert with `sips -s format jpeg -s formatOptions 82 -Z <max side>`.
- **XCUITests run locally on demand only, never in CI** (user's call): CI keeps `if: ${{ false }}` in `.github/workflows/ci.yml`. All four journeys passed on iPhone 17 Pro iOS 26 (`B24D2789…`) and iPhone 17 iOS 27.0 (`A9F21523-F10E-4219-9FD6-6F7F7FE91D73`). Run them when a change touches a journey or when the user asks.
- **App icon**: `App/Assets.xcassets/AppIcon.appiconset/AppIcon.png`, a single 1024 px universal icon drawn by a throwaway CoreGraphics script (not in the repo; redraw it if the icon changes).
- **Next: M9 ticket 08** (`.scratch/m9-photos-polish/issues/08-instruments-and-writeup.md`): the user records Instruments (list includes the ambient blur during the dismiss drag); the agent writes the numbers into the decision log and the README Performance table, marks M9 done and unblocks M8 ticket 08. The README part of the write-up is already done.
- Checking the look without XCUITest journeys: a throwaway test `ZZLookScreenshots.swift` plus `shoot.sh` (latest copy in `/private/tmp/claude-501/-Users-jesus-Code-iOS-Challenges-Voodoo/923e67fe-b6e0-4772-af03-400e45c643b7/scratchpad/`; copy them into the new session's scratchpad and fix the `S=` line) copy the test into `AppUITests/`, run it, remove it and export screenshots (`DEST=id=… shoot.sh`). Never commit it. The user's own iOS 27.2 iPhone 17 simulator may be booted; don't drive it.
- Known gaps: the iOS 17 paths (SwiftUI drag in the pager instead of the UIKit pan, material instead of glass, navigation-bar search) can't run locally. The stub fixtures share one BlurHash, so the glow looks grey under `-useStubs`. XCUITest can't capture the hero mid-stretch; the maths is covered by `HeroStretchTests`.
- Direction (user's choice): Apple Photos (iOS 26) structure plus three wow pieces: ambient glow from the BlurHash Preview, swiping between photos with parallax (ADR 0007, ticket 05), stretchy hero on the feed. The user is open to bolder design; keep the brief's grid with captions.
- M8 ticket 08 (snapshot matrix) waits until M9 is done so it records the final look. CI can't check snapshots recorded on this Mac (runner is macOS 26 / Xcode 26.6, local is macOS 27 / Xcode 27.2), so the macOS snapshot suite skips when `CI` is set; the iOS matrix will need the same treatment or a matching runtime. When it runs: devices iPhone SE, iPhone 17, iPad; ask the user for the "iPhone Duo" point size and safe areas; one Sonnet agent, check every image before merging.
- Repo is public at `github.com/jesus-rod/Gallery` (`origin`). Push after each approved commit.
- Simulators trimmed to: iPhone 17 Pro `B24D2789-AEFD-4872-BECA-40CCEBED0913` (pinned), iPhone SE 3rd gen, iPad Pro 11-inch M5, iPad mini A17 Pro on iOS 26.0; iPhone 17 on iOS 27.0. No iOS 17/18 runtime, so fallback paths can't run locally. Build into your own DerivedData in the scratchpad; launch with `-useStubs`.
- Design system: small, in `GalleryUI/DesignSystem/` (tokens, `Scrim`, `.bannerStyle()`), deliberately not a module.
- No agents or worktrees are running; only `main` exists. Never stage `project.pbxproj`, the scheme, or `Gallery.xcodeproj/project.xcworkspace/xcshareddata/` (Xcode rewrites).
- README diagrams were fixed blind (mermaid-cli download was blocked); if the user reports the flowchart still failing on GitHub, simplify its `<br/>` labels.

## Carried into M6

From M1–M5. Fold these into the M6 spec, or leave them for the milestone named.
- Ticket M3/12: run the live feed and images once with a real key in `Config/Secrets.xcconfig`, submit one Query with its second Page as well (each search Page costs one request), and open one Photo full screen (no request); never verified.
- Search edges from M4 review: the feed's refresh banner is hidden during search; Search results have no pull to refresh; the hidden feed can still finish an in-flight load more.
- Carried to M7: VoiceOver frames larger than the cell and the screen (`scaledToFill` overflow before `.clipped()`); `PhotoCreditView` needs translations to keep `%1$@` and `%2$@` literally; a 401 shows the generic error (consider an "invalid key" state).
- Open from M5 (user, Instruments): do full-screen images evict visible grid images from the shared memory cache? If so, add a small separate full-screen cache.
- Carried to M8: extract a zoom-gesture modifier from `FullScreenPhotoView` if it grows.
- Carried to M7: skip the Preview frame and fade for images already in memory (synchronous memory-cache lookup); snapshot tests for cell and empty/error states.
- Optional cleanup: both mappers repeat "rate limit, require 200, decode or `invalidData`"; extract a shared helper when a third mapper appears.
- Course rule EF-97 (`case let .x(a, b)`) conflicts with swift-format's `UseLetInEveryBoundCaseVariable`; the linter wins.
- Project file: `App/` and `AppUITests/` are synchronized folder groups, so new files there need no `project.pbxproj` edits. CI runs `swift test` then the XCUITests on the first available iPhone simulator.
- Lint all three folders: `swift format lint -r Gallery App AppUITests`.

## Settled decisions

Recorded in ADRs: own image pipeline (0001), SPM modules testable on macOS (0002), search on submit (0003), offline feed JSON store with no expiry (0004), fixed square cells in `LazyVGrid` (0005), in-flight dedup with per-caller cancellation (0006). Every decision, big or small, is listed in `docs/decision-log.md`.

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

**Renditions**: grid builds from `raw` with `w`, `dpr`, `q`, `fm=jpg` for the exact cell pixel size, keeping existing query items. Full screen is sized from `raw` to the screen (aspect fit × display scale, `q` 80), over the cached grid image, through the same pipeline and memory cache.

**Domain**: `Photo` is not Codable. Caption rule (alt description → description → localized "Untitled photo") is a pure presentation function in UI. Photographer credit is required by Unsplash guidelines.

**UI**
- One `GalleryViewModel` holding two independent paging states, Editorial feed and Search results. Cancelling search restores the feed with no request and the same scroll position; a new Query cancels the old one.
- One shared `PhotoGrid` view. 2 columns compact, 3 regular.
- States: skeleton first load; spinner footer while paging; inline retry footer on page failure; full-screen error with retry on first-page failure; rate-limited message; empty search with the Query echoed; pull to refresh on the feed; image fade-in over the Preview.
- Accessibility: Caption shown on each cell (one line over a gradient) and as its VoiceOver label, Dynamic Type, dark mode, English String Catalog.
- Full screen: push in the `NavigationStack`, nav bar hidden, `.navigationTransition(.zoom)` on iOS 18+, standard push on iOS 17. Pinch and double-tap zoom; our drag down dismisses on every version (the iOS 18+ system zoom-dismiss never fires under our gesture); Close button and VoiceOver escape; overlay with Caption and Photographer credit (referral links).

**Offline (M6)**: up to about 300 Editorial feed Photos in a versioned JSON `FeedStore`; network first, fall back to the store, save each loaded page. No expiry; a successful first Page replaces it. Search results never stored. Offline banner; pull to refresh while offline keeps the Offline feed and shows a brief error. The same Photo in both Streams shares cached Renditions; dedup is per Stream.

**Dev and tests**: `-useStubs` launch argument swaps in a `StubHTTPClient` with bundled JSON fixtures, used by XCUITests. 2–3 XCUITest acceptance tests, snapshot tests (swift-snapshot-testing, test-only) for cell and empty/error states.

**Reviews before shipping**: `/code-review`, `/security-review`, performance (`swiftui-pro` + user-recorded Instruments: Time Profiler, Allocations, SwiftUI, after ~500 images), UX pass, `/ios-skills:essential-feed diagram` for the README, pre-submit sweep.

**Repo rules**: no company names in any file or the repo name; repo is public on GitHub since 2026-11-23 (`origin`, `main`); `.scratch/` is committed; README "AI usage" section points to it.
