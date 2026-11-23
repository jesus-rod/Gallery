# 01 — Grid Rendition URL

Status: done

`UnsplashRendition.gridURL(raw:pointWidth:scale:quality:)` in `GalleryCore/UnsplashAPI`.

## Acceptance
- Keeps the raw URL's existing query items.
- Adds `w` (rounded-up points), `dpr` (scale), `q`, `fm=jpg`.
- Replaces those keys if already present instead of duplicating them.

## Comments

- Follow-up found while composing (ticket 11): with only `w`, a landscape Photo arrives cell-wide but shorter than the cell and gets upscaled by fill. `UnsplashRendition.grid(for:side:scale:quality:)` widens `w` so the shorter side covers the cell and returns the matching downsampling size (longest side), with the ratio capped at 3:1.
