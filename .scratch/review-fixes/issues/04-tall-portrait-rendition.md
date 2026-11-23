# 04 — Tall portrait Photos fill the cell at full sharpness

Status: done
Blocked by: none

`UnsplashRendition.grid` caps the aspect factor at 3:1 for both the landscape `w` widening and `maxPixelSize`. For a portrait Photo taller than 3:1, `w` is the cell side (correct) but `maxPixelSize` is capped, so ImageIO decodes it narrower than the cell and the cell upscales it. Example: aspect 0.25, side 100 pt, scale 3 → CDN returns 300 × 1200 px, decoded to 225 × 900, cell is 300 px wide.

Removing the cap for portraits would let a 10:1 Photo decode at 300 × 3000 px (3.6 MB) for one cell. Instead, for portraits taller than 3:1, ask the CDN for a centre crop at 3:1 (`h = side × 3`, `fit=crop`), so the download, the decode and the memory cost stay bounded and the width matches the cell. Landscape behaviour is unchanged.

## Files

- Edit: `Gallery/Sources/GalleryCore/UnsplashAPI/UnsplashRendition.swift`
- Edit: `Gallery/Tests/GalleryCoreTests/UnsplashRenditionTests.swift`
- Edit: `docs/decision-log.md`

## Shape

- In `grid(for:side:scale:quality:)`, when `aspectRatio < 1 / maximumAspectRatio`: URL additionally gets `h = side × maximumAspectRatio` (points, rounded up) and `fit=crop`; `maxPixelSize = side × scale × maximumAspectRatio`, rounded up.
- `sizedURL` (renamed in M5 ticket 01) keeps replacing, not duplicating, existing items; extend it with an optional height, or add the two items in `grid`. Keep `fullScreen` unchanged (it never crops).

## Tests (one at a time, red → green)

- `grid_cropsAPortraitTallerThanTheCapToTheCap` (aspect 0.25, side 100, scale 3 → `w=100`, `h=300`, `fit=crop`, `maxPixelSize == 900`, decoded width = 900 × 0.333… = 300 = cell)
- `grid_doesNotCropAPortraitWithinTheCap` (aspect 0.5 → no `h`, no `fit`, `maxPixelSize == 600`)
- `grid_replacesExistingHeightAndFitItems`
- Existing landscape and square `grid` tests stay green.

## Acceptance

- Tests pass; `swift test` green; lint clean; app builds.

## Decision log

- Portrait Photos taller than 3:1 get a CDN centre crop at 3:1 in the grid (`h`, `fit=crop`), so they fill the cell at full sharpness with bounded memory. The earlier rule capped the decode size too, which made them narrower than the cell. The full-screen Rendition never crops.

## Commit

`fix(core): crop very tall portraits at 3:1 so they fill the cell sharply`

## Comments

- `grid_replacesExistingHeightAndFitItems` passed on its first run: `sizedURL` already replaces every sizing name, so `h` and `fit` were added to that set in the step that made the crop test pass.
- `maxPixelSize` was already 900 for the example, so the crop test went red only on `h` and `fit`.
- The `photo(width:height:raw:)` helper gained a `raw` parameter (default unchanged) for the replace test.
