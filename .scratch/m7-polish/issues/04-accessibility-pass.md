# 04 — VoiceOver frames, Reduce Motion, Dynamic Type

Status: ready-for-agent
Blocked by: 03 (touches the same cell code)

View-only. Covered by previews, the feed journey's new assertion, and a manual check.

## Files

- Edit: `Gallery/Sources/GalleryUI/Gallery/PhotoGrid.swift`, `Gallery/Sources/GalleryUI/FullScreen/FullScreenPhotoView.swift`, `PhotoCreditView.swift`, `StateViews.swift`
- Edit: `AppUITests/GalleryAppUITests.swift` (one assertion in the feed journey)
- Edit: previews (add an accessibility-XXXL Dynamic Type preview of the full screen and an error state)
- Edit: `docs/decision-log.md`

## Shape

- **VoiceOver frames.** The `scaledToFill` images overflow before `.clipped()`, and clipping doesn't shrink the accessibility frame: a 200 pt cell reports 300 pt, the full-screen image is wider than the screen. Put the images in an `.overlay` of the sized shape (the cell already uses `Rectangle().aspectRatio(1).overlay { … }`; make the accessibility element the rectangle, e.g. `.accessibilityElement(children: .ignore)` on the clipped rectangle, or `.accessibilityHidden(true)` on the images plus the modifiers on the shape). Same for the full-screen image: a `Color.clear.frame(width:height:)` with the images in an overlay.
- **Feed journey assertion:** after the first cell exists, `XCTAssertLessThanOrEqual(firstCell.frame.width, grid.frame.width / 2)`.
- **Reduce Motion** (`@Environment(\.accessibilityReduceMotion)`): no image fade in the cell and full screen, no animation for the overlay toggle; the zoom transition stays (system controlled).
- **Dynamic Type:** full-screen overlay caption `lineLimit(3)` stays but the credit never truncates (`fixedSize(horizontal: false, vertical: true)`); at accessibility sizes, the overlay's text block may scroll (`ViewThatFits` or a `ScrollView` capped at ~40% height). Banners wrap (`multilineTextAlignment(.center)`, no `lineLimit(1)`).
- **Full-screen VoiceOver order:** Close, image, Caption, credit (`.accessibilitySortPriority` if needed).

## Acceptance

- Three UI tests pass with the new assertion; `swift test` green; lint clean; app builds without warnings.
- Manual (Accessibility Inspector or VoiceOver in the simulator, optional): focus boxes match the cells and the visible full-screen image.

## Decision log

- Accessibility frames come from the sized shape, not the overflowing images, so VoiceOver's focus box matches what is on screen.
- Reduce Motion removes the image fades and overlay animation; the navigation zoom stays, since the system already adapts it.

## Commit

`fix(ui): match VoiceOver frames to the visible image and respect Reduce Motion`
