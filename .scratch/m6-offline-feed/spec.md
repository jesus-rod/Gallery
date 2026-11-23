# M6 — Offline feed

Status: in progress (an agent implements the tickets; the user reviews the seams table)

## Goal

When the Editorial feed's first Page can't load (offline, rate limited, any error), the app shows the Photos it loaded last time instead of an error screen, with a banner saying they are saved and may be out of date. Decided in ADR 0004 and the roadmap's "Offline (M6)" line; this spec only shapes it.

## Use cases

1. Online launch: the first Page loads from the network and replaces the Offline feed; each later Page loaded by scrolling is added, up to 300 Photos.
2. Offline launch with a saved feed: the grid shows the saved Photos, no load more, and an Offline banner ("You're offline · Showing saved photos", or "Showing saved photos" for other errors).
3. Offline launch with nothing saved: the full-screen error with Retry, as today.
4. Pull to refresh while showing the Offline feed: success replaces it with the live feed and hides the banner; failure keeps the saved Photos and shows the brief refresh error (existing `RefreshErrorBanner`).
5. Search results are never saved. While searching, the Offline banner is hidden with the feed.
6. Images: grid Renditions already in the disk cache show offline; others keep their Preview. No change to the image pipeline.

## Seams under test

| Seam | Observed through |
|---|---|
| `CodableFeedStore(fileURL:)` (Core, actor) | `retrieve()` after `save(_:)` on a temp file: round trip of every `Photo` field, replace on save, empty when no file, empty for an unknown version, throws on corrupt data, throws when the location can't be written |
| `OfflineFeed.saving(_:to:limit:)` (Core) | A `FeedStoreSpy`'s saved arrays after the first Page and after each load more; nothing saved on failure; save failures don't fail the load; stops writing once past the limit |
| `GalleryViewModel(loadFeed:loadOfflineFeed:search:)` | `feed`, `offlineFeedReason` and `refreshError` after `load()`, `retry()`, `refresh()` with stubbed closures; the offline closure is not called when the network succeeds |
| `CodableFeedStore` / view model lifetime | Leak tracking where the SUT is a class or actor |
| App end to end | One new XCUITest journey: launch online with stubs (saves), relaunch with `-stubOffline` → banner and saved Photos; pull to refresh → brief error, Photos stay |

The banner view is logic-free (reads `offlineFeedReason`) and covered by a `#Preview` and the journey test.

## Shape

```swift
// GalleryCore/OfflineFeed/FeedStore.swift
public protocol FeedStore: Sendable {
    func retrieve() async throws -> [Photo]        // [] when nothing is saved or the version is unknown
    func save(_ photos: [Photo]) async throws      // replaces what is saved
}

// GalleryCore/OfflineFeed/CodableFeedStore.swift
public actor CodableFeedStore: FeedStore {
    public init(fileURL: URL)
}
// File: {"version": 1, "photos": [LocalPhoto]}. LocalPhoto, LocalRenditions, LocalPhotographer are
// private Codable mirrors of the domain types; Photo stays non-Codable. Write atomically
// (`Data.write(options: .atomic)`), creating the parent directory.

// GalleryCore/OfflineFeed/OfflineFeed.swift
public enum OfflineFeed {
    public typealias LoadFirstPage = @Sendable () async throws -> Paginated<Photo>
    public static let defaultLimit = 300
    public static func saving(_ load: @escaping LoadFirstPage, to store: FeedStore, limit: Int = defaultLimit) -> LoadFirstPage
}
```

`saving` wraps the first Page and every `loadMore` recursively: after each successful load it saves `items.prefix(limit)`, unless the previous save already held `limit` Photos (the prefix can't change once full). Errors from `save` are ignored (`try?`); the load's own errors propagate unchanged.

```swift
// GalleryUI
public typealias LoadOfflineFeed = @Sendable () async -> [Photo]
public init(loadFeed: LoadFeed, loadOfflineFeed: @escaping LoadOfflineFeed, search: Search)
public private(set) var offlineFeedReason: LoadError?   // non-nil while the Offline feed is shown
```

Fallback rule, in one place (view model or `StreamPager`, tested through `GalleryViewModel` only): when the feed's first Page fails with error `e` (first `load()`, `retry()`, or `refresh()` while the Offline feed is shown or nothing is loaded), call `loadOfflineFeed()`. Non-empty → feed `.loaded(photos: saved, footer: .end)` and `offlineFeedReason = LoadError(e)`. Empty → today's behaviour (`.failed(e)`, or `refreshError` on refresh). A refresh failure while the Offline feed is shown keeps it and sets `refreshError`. Any successful first Page sets `offlineFeedReason = nil`.

Composition root: `CodableFeedStore(fileURL: .applicationSupportDirectory/OfflineFeed/feed.json)`; `loadFeed = OfflineFeed.saving({ try await feedStream.firstPage() }, to: store)`; `loadOfflineFeed = { (try? await store.retrieve()) ?? [] }`. With `-useStubs` the store file is `.temporaryDirectory/OfflineFeed-stubs/feed.json`, deleted at launch when `-resetOfflineFeed` is passed; `-stubOffline` makes `StubHTTPClient` throw `URLError(.notConnectedToInternet)` (image stubs unchanged).

## Decisions taken (from ADR 0004 and the roadmap; new ones marked)

- Network first; fall back only on failure; no expiry; a successful first Page replaces the saved feed; Search results never stored. (ADR 0004)
- New: fall back on any first-Page error, not just offline, because a rate-limited or failing API is still "nothing to show"; the banner text says why.
- New: the file lives in Application Support, not Caches, so the system doesn't purge it exactly when the user is offline. It is about 300 small records.
- New: no load more on the Offline feed (`footer: .end`); paging needs the network.

## Tickets (in order)

01 `FeedStore`, `CodableFeedStore` (Core, TDD) · 02 `OfflineFeed.saving` (Core, TDD) · 03 view model fallback (UI, TDD) · 04 Offline banner, strings, previews · 05 composition root and stub flags · 06 XCUITest offline journey · 07 review notes, spec done.

## Out of scope

Saving Search results, offline full-screen Renditions, an expiry policy, reachability monitoring (the banner hides on the next successful load, not when the network returns), syncing the saved feed with the disk image cache's eviction.

## Rules for the implementer

- Strict TDD per ticket: write ONE test, run it and see it fail, write the minimal code to pass, repeat. Never write the whole test list first. Swift Testing (`@Test`, `#expect`, `@Suite(.trackingLeaks)` where a class or actor is under test), `makeSUT` with `trackForMemoryLeaks`. GalleryCore tests have their own helpers in `Gallery/Tests/GalleryCoreTests/Helpers` and `SharedTestHelpers.swift`; reuse them.
- Commands: `cd Gallery && swift test`; from the repo root `swift format lint -r Gallery App AppUITests` (fix with `swift format -i -r Gallery App AppUITests`). App build and UI tests: `xcodebuild … -project Gallery.xcodeproj -scheme GalleryApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath <your own scratch dir>`.
- No code comments anywhere. Swift 6 strict concurrency, `@Observable @MainActor` models, iOS 17 minimum.
- `App/` and `AppUITests/` are synchronized folder groups: new files need no `project.pbxproj` edits. Never stage `project.pbxproj` or the scheme.
- Decisions go into `docs/decision-log.md` under `## M6 — Offline feed` (created in ticket 01), in the same commit as the code.
- One commit per ticket, conventional subject from the ticket, 2–4 line body, the ticket's `Status: done` in the same commit. Plain `git commit` (authored by the user's git config); never a `Co-Authored-By` or Claude attribution line.
- Do not edit `.scratch/roadmap.md`; the main session updates it after merging.
