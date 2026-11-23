# 05 — A disk hit survives a failed last-used update

Status: done
Blocked by: none

`FileImageDataStore.retrieve(for:)` reads the data, then `try markUsed(file)`. If updating the modification date fails, `retrieve` throws even though it has the bytes, and `DiskCachingImageDataLoader` treats the error as a miss and fetches from the network. The last-used date only feeds LRU eviction, so a failure there should never cost a download. Same rule as the M3 decision "Store errors never fail a load".

## Files

- Edit: `Gallery/Sources/GalleryImageLoading/FileImageDataStore.swift`
- Edit: `Gallery/Tests/GalleryImageLoadingTests/FileImageDataStoreTests.swift`
- Edit: `docs/decision-log.md`

## Shape

`retrieve`: `try? markUsed(file)` after reading, return the data. `insert` keeps throwing (a failed write is already ignored one layer up).

## Test

- `retrieve_returnsTheDataWhenUpdatingTheLastUsedDateFails`: insert data, set the file immutable (`FileManager.setAttributes([.immutable: true], …)`), retrieve → the data. Clear the flag in the test's cleanup (`defer`) so the temporary directory can be removed. If setting the date on an immutable file turns out not to fail on macOS, note it in Comments and use a read-only parent directory or another way to make `setAttributes` fail; do not add a production seam just for this test.

## Acceptance

- Test passes; `swift test` green; lint clean.

## Decision log

- Updating a cached file's last-used date is best effort: if it fails, the read still counts as a hit.

## Commit

`fix(image-loading): keep a disk hit when the last-used date can't be updated`

## Comments

- The immutable flag made `setAttributes` fail on macOS as the ticket expected, so no production seam was needed. The test finds the cached file through the store directory, since the file-name helper is private.
