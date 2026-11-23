# 04 — `ZoomTransform`

Status: done
Blocked by: none

Pure value type holding the zoom and pan maths, so the view's gestures only forward numbers. Tested on macOS without SwiftUI views.

## Files

- New: `Gallery/Sources/GalleryUI/FullScreen/ZoomTransform.swift` (imports `CoreGraphics` only)
- New: `Gallery/Tests/GalleryUITests/ZoomTransformTests.swift`
- Edit: `docs/decision-log.md`

## Shape

```swift
struct ZoomTransform: Equatable {
    private(set) var scale: Double = 1
    private(set) var offset: CGSize = .zero
    var isZoomed: Bool { scale > 1 }

    func magnified(by magnification: Double, anchor: CGPoint, container: CGSize, content: CGSize) -> ZoomTransform
    func toggled(at point: CGPoint, container: CGSize, content: CGSize) -> ZoomTransform
    func panned(by translation: CGSize, container: CGSize, content: CGSize) -> ZoomTransform

    static func dismissProgress(for translation: CGSize) -> Double
    static func shouldDismiss(translation: CGSize, predictedEnd: CGSize) -> Bool

    static let maximumScale = 4.0
    static let doubleTapScale = 2.5
    static let dismissDistance = 120.0
    static let dismissFlickDistance = 300.0
}
```

Rules:
- `content` is the fitted image size in points, centred in `container`.
- **Scale** always within `1…maximumScale`.
- **Offset clamp**: `|offset.width| ≤ max(0, (content.width × scale − container.width) / 2)`, same for height. At scale 1 the offset is therefore zero.
- **Magnify** from the receiver (the transform at gesture start): `newScale = clamp(scale × magnification)`. Keep the anchor point fixed on screen: with `a = anchor − container centre`, `newOffset = a − (a − offset) × (newScale / scale)`, then clamp.
- **Toggle**: zoomed → identity. Not zoomed → `doubleTapScale`, with the tapped point moved towards the centre: `offset = −a × (doubleTapScale − 1)`, clamped.
- **Pan** from the receiver: `offset + translation`, clamped.
- **Dismiss progress**: `clamp(translation.height / dismissFlickDistance, 0, 1)`; upward drags give 0.
- **Should dismiss**: downward, and `translation.height > dismissDistance` or `predictedEnd.height > dismissFlickDistance`.

## Tests (one at a time, red → green)

Container 400 × 800, content 400 × 300 (a landscape Photo fitted to the width) unless stated.

- `init_isTheIdentity` (scale 1, offset zero, not zoomed)
- `magnified_scalesByTheMagnification`
- `magnified_neverGoesBelowOneOrAboveTheMaximum` (0.5 → 1, 10 → 4)
- `magnified_keepsTheAnchorPointUnderTheFingers` (anchor (300, 400), ×2 → offset.width == −100)
- `magnified_clampsTheOffsetSoTheImageCoversTheEdges`
- `magnified_backToOneResetsTheOffset`
- `toggled_zoomsToTheDoubleTapScaleTowardsTheTappedPoint`
- `toggled_whenZoomedReturnsToTheIdentity`
- `panned_movesTheImageWithinItsBounds`
- `panned_atOneKeepsTheImageCentred`
- `dismissProgress_growsWithTheDownwardDragUpToOne` (0 at 0, 0.5 at 150, 1 at 600)
- `dismissProgress_isZeroForAnUpwardDrag`
- `shouldDismiss_whenDraggedPastTheDistance`
- `shouldDismiss_whenFlickedDown` (short translation, large predicted end)
- `shouldDismiss_neverForAShortSlowOrUpwardDrag`

## Acceptance

- Tests above pass; `swift test` green, lint clean.

## Decision log

- Zoom and pan maths live in a pure `ZoomTransform` value, tested without views; gestures only feed it numbers. 1× to 4×, double tap toggles 2.5× towards the tapped point, and the image edges never come inside the screen edges.

## Commit

`feat(ui): add the zoom and drag-to-dismiss maths`
