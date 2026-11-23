# 05 — Snapshot tests for the cell and state views

Status: ready-for-agent
Blocked by: 01, 04

## Files

- Edit: `Gallery/Package.swift` (dependency `https://github.com/pointfreeco/swift-snapshot-testing` from `1.17.0`, only on `GalleryUITests`)
- New: `Gallery/Tests/GalleryUITests/SnapshotTests.swift` and its recorded `__Snapshots__/` folder
- Edit: `docs/decision-log.md`

## Shape

macOS only, inside `swift test`: wrap each view in `NSHostingController(rootView:)` with a fixed frame and an explicit `.environment(\.colorScheme, …)`, and assert with `.image`. Use `#if os(macOS)` around the file. Cases, light and dark each:
- `PhotoCell` with a Preview only, and with a loaded image (solid-colour `CGImage` from a test helper; `PhotoImages` closures stubbed so nothing async is needed: use `cachedImage` from ticket 03).
- `LoadErrorView` for `.offline`, `.rateLimited`, `.invalidKey`, `.generic`.
- `EmptySearchView(query: "cats")`.

Record once (`withSnapshotTesting(record: .missing)` or the `record` trait), commit the images, then run again to see them pass. If swift-snapshot-testing's Swift Testing support needs a newer version, use the newest that resolves.

## Acceptance

`swift test` green twice in a row with recorded images; lint clean.

## Decision log

- Snapshot tests (swift-snapshot-testing, test-only) render on macOS inside `swift test`, light and dark at a fixed size: fast and simulator-free, guarding layout regressions rather than exact iOS pixels.

## Commit

`test(ui): snapshot the cell and the empty and error states`
