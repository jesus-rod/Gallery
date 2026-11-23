# M9 — Photos-style polish with an ambient twist

Status: seams approved, tickets in `issues/` (direction: Photos structure + ambient glow, swipe between photos, stretchy hero)

## Goal

Make the app feel like a polished first-party app with a clear wow moment. The structure copies Apple Photos on iOS 26, which the user chose (copying a design is fine for a take-home): square grid (ADR 0005), zoom into full screen, glass controls, tap to hide them, swipe up for info. On top of that, three pieces for wow:

- **Ambient glow**: in full screen, each photo colours the screen around it (Apple Music / visionOS style), for free: the background is the BlurHash Preview we already decode at 32×32, scaled up and blurred. No extra download or decode.
- **Swipe between photos** in full screen, with a parallax slide, paging through the same Stream the photo came from (and loading more at the end).
- **Stretchy hero** at the top of the feed: the first Editorial photo full width with its credit, stretching on pull-down and drifting with parallax on scroll, then the grid.

iOS 17–18 get the same layout and effects with materials instead of glass. Before screenshot: `scratchpad/before/grid.png` (not committed). Do this milestone before M8 ticket 08, so the snapshot matrix records the final look.

## Use cases

1. **Ambient full screen**: behind the photo, its Preview fills the screen, heavily blurred and slightly dimmed; the photo sits on top. Tapping hides the controls and fades the glow to black (Photos' "focus" mode); tapping again brings both back. Dragging down to dismiss fades the glow with the background. Photos without a BlurHash fall back to black. Reduce Transparency → black.
2. **Glass controls**: Back at the top left, Share at the bottom left, Info at the bottom right; glass circles on iOS 26 (`glassEffect`), `.ultraThinMaterial` before.
3. **Title** at the top, like Photos' date and time: the Caption (one line) and "Photo by Name" below it. The bottom Caption-and-credit overlay goes away.
4. **Info sheet** (Info button, or swiping up on a photo that isn't zoomed): full Caption, the description when it differs, the Photographer credit with its referral links, and the size ("6000 × 4000 · 24 MP"). Medium and large detents.
5. **Share** opens the system share sheet with the Photo's Unsplash page (referral parameters, Caption as the preview title). No API request; the image itself is never shared, so it isn't a download under Unsplash's guidelines.
6. **Swipe between photos**: in full screen, swiping left or right shows the previous or next Photo in the same Stream (feed or the current Search results). The outgoing and incoming photos move with parallax (the image moves slower than the page), and the ambient glow cross-fades between them. Swiping near the end loads the next Page, as the grid does. Zoom resets when the page changes; while zoomed, horizontal drags pan instead of paging. Dismissing zooms back to the cell of the photo now shown, and the grid scrolls so that cell is visible.
7. **Stretchy hero**: the feed starts with the first Editorial Photo full width (about 60% of the screen height on iPhone, capped on iPad and in landscape), with its Caption and credit over a scrim. Pulling down stretches it from the top edge (no gap above it); scrolling up moves it at half speed. Tapping it opens it full screen like any cell. The grid below starts at the second Photo. Search results have no hero. The offline feed keeps the hero.
8. **Search on iOS 26** sits at the bottom, as in Photos and the system apps; iOS 17–18 keep it in the navigation bar drawer. The grid scrolls under the bars with the system scroll-edge effect.
9. **Quieter grid Caption**: shorter, lighter scrim, medium-weight text.

## Seams under test

| Seam | Observed through |
|---|---|
| `EditorialPhotosMapper` / `SearchPhotosMapper` | `links.html` → `Photo.pageURL` (fixtures gain the field) |
| Offline `FeedStore` | Round-trips `pageURL`; the store version goes up and an older store reads as empty (no crash; the network refills it) |
| `PhotoDetails(photo)` (new, pure) | Caption; description only when it differs; dimensions text; megapixels rounded (`24 MP`, `0.3 MP`) |
| `ZoomTransform.shouldShowInfo(translation:predictedEnd:)` | Upward drag past a threshold or a fast flick → true; small and sideways drags → false. Mirrors `shouldDismiss` |
| `AmbientBackdrop.opacity(isChromeVisible:dismissProgress:reduceTransparency:)` (new, pure) | Visible → full; hidden → 0; fades with dismiss progress; Reduce Transparency → 0 |
| `Parallax.offset(pageMinX:pageWidth:factor:)` (new, pure) | 0 when the page is centred; ±`factor × width` at one page away; clamped beyond |
| `HeroStretch(scrollOffset:baseHeight:)` (new, pure) | Pull down by d → height `base + d`, top pinned; scroll up by d → offset `d / 2`; never shorter than `base` while pulled |
| `GalleryViewModel` (paging from full screen) | Opening a Photo gives the Stream's Photos and the index; reaching the last few pages in full screen triggers the same load more as the grid (one request in flight, as today) |
| `FullScreenRoute` | Now names the Stream and the starting Photo; still `Hashable` |
| Views | Previews now; snapshots come from M8 ticket 08, recorded after this milestone |
| App end to end | The full-screen journey gains: swipe left shows the second Photo's Caption in the title; the credit assertion moves into the Info sheet. The feed journey checks the hero exists and opens full screen |

## Shape

- **Ambient backdrop**: `Image(decorative: preview).resizable()` at the screen size with `.blur(radius: ~60)` and a dim overlay. The blur runs on a 32×32 image scaled up, which is cheap; measure once in Instruments (SwiftUI and Core Animation templates) and record the numbers. No new image work in the pipeline.
- **Paging**: a horizontal `ScrollView` with `.scrollTargetBehavior(.paging)`, `LazyHStack` of pages and `.scrollPosition(id:)` (all iOS 17). Each page is today's zoomable `FullScreenPhotoView` content; only the visible page (±1) holds a full-size image, so memory stays flat after hundreds of swipes. Parallax via `.visualEffect` (iOS 17) reading the page's frame in the scroll view, so no `GeometryReader` or state writes per frame. `.scrollDisabled(transform.isZoomed)` hands drags to the pan gesture while zoomed.
- **Zoom transition on dismiss**: the route keeps a binding to the current Photo id; the grid passes its `zoomTransitionSource` per cell already, so the source for the current Photo is found by id. The grid restores its `scrollPosition(id:)` to the current Photo before the dismiss animation. Record in an ADR: full screen pages through the Stream instead of showing one Photo (ADR 0007).
- **Hero**: a `StretchyHeader` view at the top of the feed's `ScrollView`, using `.visualEffect` / `onScrollGeometryChange` (iOS 18) with an iOS 17 path via `GeometryReader` inside the header only. Its Rendition is sized for its own frame through the same pipeline (one more Rendition size, cached like the others).
- **Design system**: `.glassCircle()` modifier (`glassEffect(.regular.interactive(), in: .circle)` under `#available(iOS 26, macOS 26, *)`, `.ultraThinMaterial` circle otherwise). `Design.Opacity.controlFill` goes away; `Design.Motion` gains the page and hero values.
- `FullScreenCloseLayer` becomes `FullScreenChromeLayer` (top bar + bottom bar), still value inputs only so pinch and pan frames skip it (M8 decision). `FullScreenCaptionLayer` is deleted; `PhotoCreditView` moves into the sheet and the hero.
- `Photo` gains `pageURL: URL` (Unsplash's `links.html`), required like the profile URL.

## Order (tickets)

1. Core: `pageURL` in mappers, fixtures and the store.
2. Design system: `.glassCircle()`; chrome layer with title, Back, Share, Info.
3. Info sheet + swipe up.
4. Ambient backdrop.
5. Swipe between photos with parallax (ADR 0007), including load more and the dismiss target.
6. Stretchy hero.
7. iOS 26 bottom search, quieter Caption.
8. Instruments pass for the new effects (user records; agent writes up), decision log, README section.

## Out of scope

- Likes, downloads, collections: they need more requests or a login.
- Shrinking the photo into the top half when the Info sheet opens (Photos does this); the zoom maths assumes the full container.
