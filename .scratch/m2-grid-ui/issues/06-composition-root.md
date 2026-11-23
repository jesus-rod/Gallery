# 06 — Composition root

Status: done
Blocked by: 05

`GalleryApp` wires the real stack: API `URLSession` → `URLSessionHTTPClient` → `AuthorizingHTTPClient` (key from Info.plist) → `UnsplashEndpoint.editorial` + `EditorialPhotosMapper` → `PhotoStream` → `GalleryViewModel`.

## Acceptance
- App builds and shows the live Editorial feed with a key in `Secrets.xcconfig`.
- A missing key never crashes; requests fail into the generic error state.

## Comments

- No `Secrets.xcconfig` on the dev machine at implementation time: verified the missing-key path in the simulator (generic error with retry, no crash). The live feed still needs a run with a real key.
