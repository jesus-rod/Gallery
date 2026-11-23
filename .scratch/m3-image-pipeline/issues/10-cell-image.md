# 10 — Cell image: Preview, Rendition, fade

Status: ready-for-agent
Blocked by: 01, 07, 08, 09

`PhotoImageModel` (`@Observable @MainActor`) per cell in `GalleryUI`: `state` is `.preview(CGImage?)` then `.image(CGImage)`. `PhotoCell` measures its size with `GeometryReader` (or `onGeometryChange`), builds the grid Rendition URL, and loads in `.task(id: url)`. `PhotoGrid` asks the prefetcher for items i+1…i+k on appear.

## Acceptance
- Initial state is the cached Preview (nil without BlurHash).
- Successful load → `.image`; failure → stays on Preview.
- Cancelled load leaves the state unchanged.
- Image fades in over the Preview (view, `#Preview`).
- No leak.
