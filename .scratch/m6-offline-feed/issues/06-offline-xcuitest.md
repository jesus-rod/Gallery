# 06 — XCUITest: offline journey

Status: ready-for-agent
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
