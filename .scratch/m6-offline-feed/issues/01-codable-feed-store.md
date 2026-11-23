# 01 — `FeedStore` and `CodableFeedStore`

Status: done
Blocked by: none

## Files

- New: `Gallery/Sources/GalleryCore/OfflineFeed/FeedStore.swift`
- New: `Gallery/Sources/GalleryCore/OfflineFeed/CodableFeedStore.swift`
- New: `Gallery/Tests/GalleryCoreTests/CodableFeedStoreTests.swift`
- Edit: `docs/decision-log.md` (new `## M6 — Offline feed` heading at the end)

## Shape

See spec "Shape". Private `Codable` mirrors (`LocalPhoto` etc.) inside `CodableFeedStore.swift`, mapping both ways. Envelope `{version: 1, photos: [...]}`; `retrieve()` returns `[]` when the file is missing or `version != 1`, and throws when the data can't be decoded. `save` creates the parent directory and writes atomically.

## Tests (one at a time; each test gets its own file URL under `FileManager.default.temporaryDirectory/<UUID>/feed.json`, removed afterwards)

1. `retrieve` on a missing file returns `[]`.
2. `retrieve` after `save` returns the same Photos (use two Photos with every field set, including nil `blurHash`/descriptions on one).
3. A second `save` replaces the first.
4. `retrieve` twice returns the same Photos (no side effects).
5. A file with `"version": 2` returns `[]`.
6. Corrupt data throws.
7. `save` to a location that can't be written throws (e.g. a file URL whose parent path is an existing regular file).
8. `save` creates a missing parent directory.

## Decision log

- The Offline feed is one versioned JSON file (`version: 1`) read and written whole by an actor; an unknown version reads as empty rather than failing, so a future format change just starts fresh.
- It lives in Application Support, not Caches, so the system doesn't purge it exactly when the user is offline.

## Commit

`feat(core): save the Offline feed as a versioned JSON file`
