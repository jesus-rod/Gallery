# 06 — Composition root

Status: ready-for-agent
Blocked by: 05

`GalleryApp` wires the real stack: API `URLSession` → `URLSessionHTTPClient` → `AuthorizingHTTPClient` (key from Info.plist) → `UnsplashEndpoint.editorial` + `EditorialPhotosMapper` → `PhotoStream` → `GalleryViewModel`.

## Acceptance
- App builds and shows the live Editorial feed with a key in `Secrets.xcconfig`.
- A missing key never crashes; requests fail into the generic error state.
