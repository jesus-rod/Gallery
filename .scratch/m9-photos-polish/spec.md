# M9 — Photos-style polish

Status: seams approved, tickets next

## Goal

Make the app look and feel like Apple Photos on iOS 26, which the user chose as the reference (copying a design is fine for a take-home). Photos fits what we already have: square cells (ADR 0005), a zoom transition into a black full-screen view, tap to hide the controls. We copy its iOS 26 look: glass controls, light/dark full-screen background, title at the top, actions at the bottom, swipe up for info. iOS 17–18 get the same layout with materials instead of glass.

Before screenshot: `scratchpad/before/grid.png` (not committed). Do this milestone before M8 ticket 08, so the snapshot matrix records the final look.

## Use cases

1. Full screen in light mode shows the photo on white with the controls; one tap hides the controls and turns the background black (and back). Dark mode is always black. Dragging down to dismiss still fades the background.
2. Full-screen controls are glass circles (iOS 26 `glassEffect`, `.ultraThinMaterial` before): Back at the top left, Share at the bottom left, Info at the bottom right.
3. The top of the full screen shows a two-line title like Photos' date and time: the Caption (one line) and "Photo by Name" below it. The Caption-and-credit overlay at the bottom goes away.
4. Info (button, or swiping up on a photo that isn't zoomed) opens a sheet with the full Caption, the description when it differs from the Caption, the Photographer credit with its referral links, and the size ("6000 × 4000 · 24 MP"). Medium and large detents.
5. Share opens the system share sheet with the Photo's Unsplash page (with referral parameters) and the Caption as the preview title. It costs no API request and doesn't count as a download under Unsplash's guidelines (the image itself is never shared).
6. On iOS 26 the search field sits at the bottom of the screen, where Photos and the system apps put it; iOS 17–18 keep it in the navigation bar drawer. The grid scrolls under the bars with the system scroll-edge effect.
7. The grid Caption is quieter: a shorter, lighter scrim and medium-weight text, so the grid reads as photos first.
8. (Optional, ticket 06) Pinching the grid switches between 2 and 3 columns, as in Photos, animated and kept across rotation.

## Seams under test

| Seam | Observed through |
|---|---|
| `EditorialPhotosMapper` / `SearchPhotosMapper` | `links.html` → `Photo.pageURL` (fixtures gain the field) |
| Offline `FeedStore` | Round-trips `pageURL`; the store version goes up and an older store is read as empty (no crash, network refills it) |
| `UnsplashAttribution.referralURL(_:appName:)` | Already tested; reused for the page URL |
| `PhotoDetails(photo)` (new, pure, GalleryUI) | Caption, description only when it differs, dimensions text, megapixels rounded (`24 MP`, `0.3 MP`) |
| `ZoomTransform.shouldShowInfo(translation:predictedEnd:)` | Upward drag past a threshold or a fast flick → true; small drags, sideways drags → false. Mirrors `shouldDismiss` |
| `FullScreenChrome.background(colorScheme:isVisible:)` (new, pure) | light + visible → white; light + hidden → black; dark → black |
| `GridDensity` (ticket 06, pure) | Pinch magnification past a threshold → 2 ↔ 3 columns; clamped to 2…3 |
| Views | Previews now; snapshots come from M8 ticket 08, recorded after this milestone |
| App end to end | The full-screen journey: the credit assertion moves into the Info sheet (tap Info, find `photo-credit`) |

## Shape

- One design-system modifier `.glassCircle()` (in `GalleryUI/DesignSystem/`): `glassEffect(.regular.interactive(), in: .circle)` under `if #available(iOS 26, macOS 26, *)`, otherwise `.ultraThinMaterial` in a circle. Size is `Design.Size.hitTarget`. `Design.Opacity.controlFill` goes away.
- `FullScreenCloseLayer` becomes `FullScreenChromeLayer`: top bar (Back + title) and bottom bar (Share, Info), still value inputs only so pinch and pan frames skip it (M8 decision). `FullScreenCaptionLayer` is deleted; `PhotoCreditView` moves into the sheet.
- The sheet is a plain `.sheet` with `.presentationDetents([.medium, .large])`. Photos shrinks the photo into the top half; we don't (the zoom maths assumes the full container), recorded as accepted.
- `Photo` gains `pageURL: URL` (Unsplash's `links.html`). Required, like the profile URL.
- iOS 26 search placement: `.searchable` with the default placement under `#available(iOS 26, *)`, `.navigationBarDrawer(displayMode: .always)` before.

## Out of scope (ask if wanted)

- Swiping left and right between photos in full screen (Photos' paging). It's the most Photos-like gesture, but it touches the route, the zoom transition source and the gestures, which makes it a milestone of its own.
- Likes, downloads, collections: they need more API requests or a user login.
