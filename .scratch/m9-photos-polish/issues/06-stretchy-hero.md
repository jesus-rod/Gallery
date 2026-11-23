# 06 — Stretchy hero at the top of the feed

Status: ready-for-agent
Blocked by: 02

## Shape

- New `HeroHeader` view at the top of the feed's `ScrollView` (not in Search results): the first Photo full width, height `Design.Hero.height(for: containerSize)` (about 60% of the height on iPhone portrait, capped at 480 pt on iPad and 50% in landscape). Caption (`.title2.bold()`, 2 lines) and `PhotoCreditView` over a `Scrim` at the bottom.
- Stretch and parallax through `.visualEffect` reading the header's frame in `.scrollView` space, computed by a pure `HeroStretch` (pull down by d → scale from the top so the height becomes `base + d`; scroll up by d → offset `d / 2`). No state writes per frame, so the grid below is not re-evaluated while scrolling.
- The grid gets `photos.dropFirst()`; the hero is a zoom-transition source and opens full screen at index 0 (works with ticket 05's pager if it lands first; otherwise a single Photo).
- The hero's Rendition is sized to its own frame through the same `PhotoImages.image` path (one more Rendition size).
- Offline feed keeps the hero. Skeleton gets a hero-shaped placeholder.

## Files

- New: `Gallery/Sources/GalleryUI/Gallery/HeroHeader.swift`, `Gallery/Sources/GalleryUI/Gallery/HeroStretch.swift`
- Edit: `DesignSystem/Design.swift` (`Design.Hero`), `Gallery/PhotoGrid.swift` (optional header slot), `Gallery/GalleryRootView.swift`, `Gallery/SkeletonGrid.swift`, `Gallery/GalleryPreviews.swift`
- New: `Gallery/Tests/GalleryUITests/HeroStretchTests.swift`
- Edit: `AppUITests/GalleryAppUITests.swift` (feed journey: `hero` exists; tapping it opens full screen)

## Tests (one at a time)

1. No scroll → height `base`, offset 0, scale 1.
2. Pulled down by 100 → height `base + 100`, top pinned (offset −100 in scroll space compensated so no gap).
3. Scrolled up by 100 → offset 50 (half speed), height `base`.
4. `Design.Hero.height`: iPhone portrait ≈ 60%; iPad capped at 480; landscape 50%.

## Decision log

- The feed opens with a stretchy hero of its first Photo, then the grid from the second Photo. Search results stay a plain grid: a hero there would push results down for a list the user asked for.

## Commit

`feat(ui): stretchy hero header on the feed`
