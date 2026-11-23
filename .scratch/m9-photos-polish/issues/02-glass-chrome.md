# 02 — Glass full-screen chrome: title, Back, Share, Info

Status: ready-for-agent
Blocked by: 01

## Files

- New: `Gallery/Sources/GalleryUI/DesignSystem/View+GlassCircle.swift` (`.glassCircle()`: `glassEffect(.regular.interactive(), in: .circle)` under `#available(iOS 26, macOS 26, *)`, else `.ultraThinMaterial` in a circle; frame `Design.Size.hitTarget`)
- Edit: `Gallery/Sources/GalleryUI/DesignSystem/Design.swift` (remove `Opacity.controlFill`)
- Rename: `FullScreen/FullScreenCloseLayer.swift` → `FullScreen/FullScreenChromeLayer.swift`. Top bar: Back (`chevron.backward`, glass) at the leading edge, two-line title centred (Caption, one line, `.headline`; "Photo by Name", `.footnote`, secondary). Bottom bar: `ShareLink` (glass, `square.and.arrow.up`) leading, Info (glass, `info.circle`) trailing; Info calls a closure input (ticket 03 wires the sheet; here it is a no-op in previews). Value inputs only (M8 decision).
- Delete: `FullScreen/FullScreenCaptionLayer.swift` (the credit moves to the sheet in 03; until then keep `PhotoCreditView` under the title so attribution never disappears)
- Edit: `FullScreen/FullScreenPhotoView.swift`, `FullScreen/FullScreenPreviews.swift`
- Edit: `Gallery/Sources/GalleryUI/Localizable.xcstrings` ("Back", "Share", "Info", "Photo by %@")
- Edit: `AppUITests/GalleryAppUITests.swift` (`full-screen-close` identifier now on Back; keep the identifier so the journey still passes)

## Tests

- Share item: the shared URL is `UnsplashAttribution.referralURL(photo.pageURL, appName:)`. Put the URL choice in a small pure function (`shareURL(for:appName:)`) and test it in `GalleryUITests`.
- Everything else is visual: previews in light and dark, chrome visible and hidden.

## Decision log

- Full-screen controls are glass circles (iOS 26 `glassEffect`, material before), in Photos' layout: Back top left, title centred, Share and Info at the bottom. The Caption and credit move from a bottom overlay into the title, which keeps the photo unobstructed.

## Commit

`feat(ui): glass full-screen controls with title, share and info`
