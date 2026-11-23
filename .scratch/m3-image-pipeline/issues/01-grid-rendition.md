# 01 — Grid Rendition URL

Status: ready-for-agent

`UnsplashRendition.gridURL(raw:pointWidth:scale:quality:)` in `GalleryCore/UnsplashAPI`.

## Acceptance
- Keeps the raw URL's existing query items.
- Adds `w` (rounded-up points), `dpr` (scale), `q`, `fm=jpg`.
- Replaces those keys if already present instead of duplicating them.
