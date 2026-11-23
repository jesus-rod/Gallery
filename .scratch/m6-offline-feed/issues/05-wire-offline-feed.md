# 05 — Composition root and stub flags

Status: done
Blocked by: 02, 03

## Files

- Edit: `App/GalleryApp.swift`
- Edit: `App/Stubs/StubHTTPClient.swift`
- Edit: `docs/decision-log.md`

## Shape

See spec "Composition root". Store URL: `URL.applicationSupportDirectory.appending(path: "OfflineFeed/feed.json")`; under `-useStubs`, `URL.temporaryDirectory.appending(path: "OfflineFeed-stubs/feed.json")`, deleted at launch if `-resetOfflineFeed` is in the arguments. `StubHTTPClient` gains an `isOffline` flag set from `-stubOffline`, throwing `URLError(.notConnectedToInternet)` for every API request. Keep all stub code inside `#if DEBUG`.

## Acceptance

- App builds without warnings; existing three XCUITests pass; `swift test` green; lint clean.
- Manual (simulator, optional): launch with stubs, then relaunch with `-useStubs -stubOffline` → saved feed with banner.

## Decision log

- `-stubOffline` and `-resetOfflineFeed` launch arguments let the XCUITests drive the offline path with a store separate from the real one.

## Commit

`feat(app): save the feed for offline use and add offline stub flags`
