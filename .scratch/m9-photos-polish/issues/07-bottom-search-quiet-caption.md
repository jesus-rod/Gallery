# 07 — Bottom search on iOS 26, quieter grid Caption

Status: ready-for-agent
Blocked by: none (do after 06 so the hero and the bars are checked together)

## Files

- Edit: `Gallery/GalleryRootView.swift` (`searchField`: default `.searchable` placement under `#available(iOS 26, *)`, which puts the field at the bottom on iPhone; `.navigationBarDrawer(displayMode: .always)` before)
- Edit: `Gallery/PhotoCell.swift` (caption `.caption.weight(.medium)`, top padding `Design.Spacing.small`), `DesignSystem/Scrim.swift` / `Design.swift` (cell scrim opacity token lowered to about 0.45; full-screen scrim unchanged)
- Edit: `AppUITests/GalleryAppUITests.swift` only if the search field query changes (it shouldn't: same `searchFields` element)

## Tests

- Visual only; run the search journey on iOS 26 to confirm the bottom field still submits and cancels.

## Decision log

- On iOS 26 the search field moves to the bottom, where the system apps put it; iOS 17–18 keep it in the navigation bar drawer. The grid Caption scrim is lighter so the grid reads as photos first.

## Commit

`feat(ui): bottom search on iOS 26 and a quieter grid caption`
