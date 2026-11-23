# 02 — Swift package with module targets

Status: done
Blocked by: 01

Create `Gallery/Package.swift` (Swift 6 language mode, iOS 17 and macOS 14) with library targets `GalleryCore`, `GalleryImageLoading`, `GalleryUI` and Swift Testing targets for each. `GalleryUI` depends on Core and ImageLoading; Core and ImageLoading depend on nothing.

## Acceptance

- `swift build` and `swift test` succeed from `Gallery/`.
- Each test target holds one file that imports its module, proving the wiring; M1's first real test replaces it.
