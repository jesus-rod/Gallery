# Review fixes after M9

Status: done

## Goal

Fix what the `/swiftui-pro` and `/ios-skills:essential-feed` reviews of 2026-11-23 confirmed, plus housekeeping for `3760214` (full-screen chrome after a search). The user agreed this cut on 2026-11-23.

## Findings fixed here

| # | Finding | Source | Ticket |
|---|---|---|---|
| 1 | `3760214` added a doc comment (repo rule: no code comments) and no decision-log line. | roadmap working loop | 01 |
| 2 | `PhotoDetails` formats megapixels with `String(format: "%.1f")`: C-style and not localized ("2.5 MP" for a French user, should be "2,5 MP"). | swiftui-pro | 02 |
| 3 | The refresh-error banner slides in with `.move(edge: .top)` under `.animation(.default)`, ignoring Reduce Motion; it auto-dismisses after 3 s without a VoiceOver announcement. | swiftui-pro | 03 |
| 4 | GalleryUI classifies transport errors itself (`LoadError.init` switches on `URLError` codes and `UnsplashAPIError`), and the mapping is not triangulated: `.networkConnectionLost`, `.dataNotAllowed`, `.timedOut` and `unauthorized → invalidKey` have no test. | essential-feed EF-14, EF-32 | 04 |

## Not in this cut (recorded so they aren't lost)

- EF-107: stub and launch-argument branches live in the production `CompositionRoot` (`App/GalleryApp.swift`). Course shape: a separate debugging composition root picked once.
- EF-23: `InFlightDedupImageDataLoader.waiterCount` and `ImagePrefetcher.inFlightCount` exist only for `@testable` tests; assert through a spy decoratee instead.
- EF-81 / swiftui-pro: `ZoomablePhotoPage` (208 lines) and `GalleryRootView` (205) carry several responsibilities; extract `FeedContent` / `SearchContent` views and the zoom gestures.
- swiftui-pro: `FullScreenPhotoView.pager` recomputes `currentIndex` per visible page; read it once.
- EF-80: force unwraps on literals in `UnsplashAttribution.swift:17`, `GalleryApp.swift:32`, `BlurHash.swift:118`.
- `ImagePipeline.evictDiskCache` uses `Task.detached` needlessly (the store is an actor).
- Checked and not a finding: `ForEach(Array(pages.enumerated()), …)` must keep the `Array` (the `EnumeratedSequence` collection conformance is iOS 26 only, target is iOS 17); cell `onTapGesture` is a logged decision; `GalleryViewModelTests` already leak-track the SUT.

## Rules for the implementer

Same as `.scratch/m5-full-screen/spec.md` "Rules for the implementer": `/tdd` (one failing test, minimal code), Swift Testing, `makeSUT` + leak tracking, no code comments, `swift test` in `Gallery/` and `swift format lint -r Gallery App AppUITests` from the repo root, own `-derivedDataPath` in the scratchpad, explicit `git add` paths, never stage `project.pbxproj`, the scheme or `project.xcworkspace/xcshareddata/`. One commit per ticket, authored by the user, no attribution line (Claude may commit directly since 2026-11-23). Decision-log lines go under a new `## Review fixes (M9)` heading at the end of `docs/decision-log.md`, created by ticket 01.

Agree the seam of ticket 04 with the user before writing its first test.
