# 04 — Ambient glow behind the full-screen photo

Status: done
Blocked by: 02

## Files

- New: `Gallery/Sources/GalleryUI/FullScreen/AmbientBackdrop.swift` (view: the Preview `CGImage` resizable to fill, `.blur(radius: Design.Ambient.blurRadius)`, a dim overlay; plus a pure `static func opacity(isChromeVisible:dismissProgress:reduceTransparency:) -> Double`)
- Edit: `DesignSystem/Design.swift` (`Design.Ambient` blur radius and dim)
- Edit: `FullScreen/FullScreenPhotoView.swift` (black base, backdrop above it, photo above; the backdrop replaces the current `Color.black.opacity(...)` fade). No BlurHash → black only.
- New: `Gallery/Tests/GalleryUITests/AmbientBackdropTests.swift`
- Edit: `FullScreen/FullScreenPreviews.swift` (preview with a colourful Preview)

## Tests (one at a time)

1. Chrome visible, no drag → 1.
2. Chrome hidden → 0.
3. Dismiss progress 0.5 with chrome visible → 0.5 (scales with `1 - progress`).
4. Reduce Transparency → 0.

## Notes

- The blur runs on a 32×32 image scaled to the screen; keep the image layer `.drawingGroup()`-free unless Instruments says otherwise. Add a line to ticket 08's Instruments list: hitches during the dismiss drag with the backdrop on.
- Animate opacity changes with `Design.Motion` (none with Reduce Motion).

## Decision log

- The full screen has an ambient glow made from the photo's BlurHash Preview, already decoded at 32×32: no extra download, decode or cache entry. Hidden controls fade it to black; Reduce Transparency turns it off.

## Commit

`feat(ui): ambient glow behind the full-screen photo`
