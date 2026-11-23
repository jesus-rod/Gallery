# 03 — Info sheet, opened by the Info button or a swipe up

Status: done
Blocked by: 02

## Files

- New: `Gallery/Sources/GalleryUI/FullScreen/PhotoDetails.swift` (pure: caption, optional description, dimensions text, megapixels text)
- New: `Gallery/Sources/GalleryUI/FullScreen/PhotoInfoSheet.swift` (full Caption, description when it differs, `PhotoCreditView`, "6000 × 4000 · 24 MP"; `.presentationDetents([.medium, .large])`, `.presentationDragIndicator(.visible)`)
- Edit: `FullScreen/ZoomTransform.swift` (`static func shouldShowInfo(translation:predictedEnd:) -> Bool`, mirroring `shouldDismiss`)
- Edit: `FullScreen/FullScreenPhotoView.swift` (`@State isShowingInfo`; the drag gesture opens it on an upward drag when not zoomed; Info button opens it), `FullScreenChromeLayer.swift` (credit leaves the title)
- New: `Gallery/Tests/GalleryUITests/PhotoDetailsTests.swift`; edit `ZoomTransformTests.swift`
- Edit: `Localizable.xcstrings`, `AppUITests/GalleryAppUITests.swift` (tap `full-screen-info`, assert `photo-credit` exists in the sheet)

## Tests (one at a time)

1. `PhotoDetails`: description is nil when equal to the Caption, present when different.
2. Dimensions text "6000 × 4000"; megapixels "24 MP" for 6000×4000, "0.3 MP" for 640×480 (one decimal under 10 MP, none above).
3. `shouldShowInfo`: an upward drag past the threshold → true; a fast upward flick (predicted end) → true; a small drag → false; a mostly sideways drag → false; a downward drag → false.

## Decision log

- Info opens as a medium-detent sheet. Photos also shrinks the photo into the top half; we don't, because the zoom maths assumes the full container (accepted).

## Commit

`feat(ui): show photo info in a sheet, opened by a swipe up or the info button`
