# 06 — XCUITest: offline journey

Status: done
Blocked by: 04, 05

One journey (the project keeps one XCUITest per journey). Details are unit tested in 01–03.

## Files

- Edit: `AppUITests/GalleryAppUITests.swift`

## Test

`test_launchingOffline_showsTheSavedFeedWithABannerAndKeepsItOnFailedRefresh`:
1. Launch with `["-useStubs", "-resetOfflineFeed"]`; wait for `app.images["Fixture photo 1"]`. `app.terminate()`.
2. Launch with `["-useStubs", "-stubOffline"]` → `offline-banner` exists; "Fixture photo 1" exists.
3. Pull to refresh on `photo-grid` (drag from the first cell's top down ~300 pt) → `refresh-error` appears; "Fixture photo 1" still exists.

No production change expected; note any in Comments.

## Acceptance

All four UI tests pass; lint clean.

## Commit

`test(app): cover launching offline with a saved feed`

## Comments

- Deviation: the test does not assert `refresh-error`. XCUITest blocks until the app is idle, and the app is not idle while the 3 s refresh banner shows, so the gesture only returned after the banner had gone (confirmed with temporary logging: the failed refresh ran and set the error). The test pulls from the Offline banner, then asserts the saved Photos and the Offline banner are still there. The failed refresh itself is covered by `GalleryViewModelTests`.
- No production change.
