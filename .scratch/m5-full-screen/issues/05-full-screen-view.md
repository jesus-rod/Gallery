# 05 — Full-screen view, navigation and gestures

Status: ready-for-agent
Blocked by: 01, 02, 03, 04

The view layer. No new unit tests: everything with branches was tested in tickets 01–04. Covered by `#Preview`s here and the XCUITests in ticket 06. **The existing six XCUITests must pass unchanged.**

## Step 0 — device check for decision 3 (do this first, before polishing)

Build a rough version (route, push, zoom transition, `MagnifyGesture` + pan `DragGesture` when zoomed) and run it on an iOS 18+ simulator or device. Zoom a Photo in, then pan it around, including downwards. Record in this ticket's Comments whether the system's zoom-dismiss gesture ever wins over panning.
- It doesn't → keep decision 3: system dismiss on iOS 18+, our drag dismisses only on iOS 17.
- It does → our own drag dismisses on both versions, and the iOS 18 system gesture is left to the zoom transition only when not zoomed if that is controllable; otherwise note it. Either way, add a decision-log line saying which one won and why.

## Files

- New: `Gallery/Sources/GalleryUI/FullScreen/FullScreenRoute.swift`
- New: `Gallery/Sources/GalleryUI/FullScreen/FullScreenPhotoView.swift`
- New: `Gallery/Sources/GalleryUI/FullScreen/PhotoCreditView.swift`
- New: `Gallery/Sources/GalleryUI/FullScreen/View+ZoomTransition.swift`
- New: `Gallery/Sources/GalleryUI/FullScreen/FullScreenPreviews.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/PhotoGrid.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryRootView.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryPreviews.swift` (new init parameter)
- Edit: `Gallery/Sources/GalleryUI/Localizable.xcstrings` (in the catalog's own format, sorted)
- Edit: `App/GalleryApp.swift`
- Edit: `docs/decision-log.md`

## Shape

**Route.** `struct FullScreenRoute: Hashable { let photo: Photo; let gridSize: ImageSize; let sourceID: String }`. `sourceID` is `"feed-<id>"` or `"search-<query>-<id>"`, so a Photo in both the hidden feed and Search results has two distinct transition sources.

**Root.** `GalleryRootView(viewModel:images:referralAppName:)`. `@State private var path: [FullScreenRoute] = []`, `@Namespace private var zoomNamespace`, `NavigationStack(path: $path)`, `.navigationDestination(for: FullScreenRoute.self) { FullScreenPhotoView(route: $0, images: images, referralAppName: referralAppName).zoomTransition(sourceID: $0.sourceID, in: zoomNamespace) }`. The composition root passes `"gallery_ios"`.

**Grid.** `PhotoGrid` gains `streamID: String`, `zoomNamespace: Namespace.ID` and `onOpen: (FullScreenRoute) -> Void`. Each `PhotoCell` gets `.zoomTransitionSource(id:in:)`, `.onTapGesture { onOpen(route) }`, `.accessibilityAction { onOpen(route) }` (the default action, so VoiceOver double tap opens it) and `.accessibilityHint("Opens the photo full screen")`. Keep the `.isImage` trait only; no `NavigationLink`, no `.isButton`, so the XCUITests still find cells as `app.images`.

**Transition helpers** (`View+ZoomTransition.swift`): `zoomTransitionSource(id:in:)` → `matchedTransitionSource(id:in:)` and `zoomTransition(sourceID:in:)` → `navigationTransition(.zoom(sourceID:in:))`, both only `if #available(iOS 18, *)`, otherwise the view unchanged. Wrap in `#if os(iOS)` where the macOS build needs it (ADR 0002).

**Full-screen view.**
- Black background ignoring safe areas; `.toolbar(.hidden, for: .navigationBar)`; status bar hidden while the overlay is hidden.
- `@State model = FullScreenImageModel(photo:images:gridSize:)`, driven by `.task(id: fittingSize) { guard width and height > 0; await model.load(fitting:) }`, where `fittingSize` comes from `onGeometryChange` of the container and `displayScale`.
- The image frame is the Photo's aspect ratio fitted to the container (`.aspectRatio(photo aspect, contentMode: .fit)`), and whichever image the state holds fills that frame (`scaledToFill` + `clipped`), so the 32 × 32 Preview and the grid image keep the Photo's shape. The full image fades in over the lower one (0.25 s, like the cell).
- `scaleEffect(transform.scale)` and `offset(transform.offset)`, from `ZoomTransform`. Gestures: `MagnifyGesture` (anchor from `startAnchor`), `SpatialTapGesture(count: 2)` → `toggled`, single tap → toggle overlay (single tap must wait for the double tap to fail: `.onTapGesture(count: 2)` before `.onTapGesture(count: 1)` or `exclusively(before:)`), `DragGesture`: pan when zoomed, otherwise (iOS 17, per step 0) offset the image vertically and fade the background by `dismissProgress`, then `dismiss()` if `shouldDismiss`, else spring back.
- Zooming in hides the overlay; it does not reappear by itself.
- Overlay (bottom, over a gradient for contrast): Caption (`caption(for:)`, up to 3 lines) and `PhotoCreditView`. Close button top leading (`xmark`, label "Close"), shown and hidden with the overlay.
- `PhotoCreditView`: "Photo by <name> on Unsplash" as one `Text` built from an `AttributedString` of the localized format `"Photo by %1$@ on %2$@"`, with `.link` set on the name (`UnsplashAttribution.referralURL(photographer.profileURL, appName:)`) and on "Unsplash" (`unsplashURL(appName:)`). Dynamic Type.

**Accessibility.**
- Image: one element, label = Caption, `.isImage`, value "Loading" until `isFullImageShown`, identifier `full-screen-photo`.
- Close: identifier `full-screen-close`. Credit: identifier `photo-credit`.
- `.accessibilityAction(.escape) { dismiss() }`.

**Strings to add.** "Close", "Opens the photo full screen", "Photo by %1$@ on %2$@" ("Loading" already exists).

**Previews.** `#Preview("Full screen")` and `#Preview("Full screen, image failed")` with preview `PhotoImages`.

## Acceptance

- Tapping a cell in the feed and in Search results opens the Full-screen view; Close and back return to the grid at the same position. Zoom transition on iOS 18+, standard push on iOS 17.
- Pinch, double tap, pan when zoomed and drag to dismiss behave as in the spec.
- The six existing XCUITests pass unchanged. App builds without warnings; `swift test` green; lint clean.

## Decision log

- Opening a Photo pushes a `FullScreenRoute` on the existing `NavigationStack`, so the grids and their scroll positions stay alive underneath. The cell opens it with a tap gesture and a default accessibility action instead of a `NavigationLink`, which would turn the cell into a button for accessibility.
- iOS 18+ zooms from the cell (`matchedTransitionSource` / `.zoom`); iOS 17 uses the standard push, because `NavigationStack` has no cross-fade push and faking one would mean presenting over the stack.
- The transition source ID includes the Stream, because the same Photo can sit in the hidden feed and in Search results at once.
- The drag-to-dismiss outcome of step 0 (which gesture dismisses on iOS 18+).
- A Close button and the VoiceOver escape gesture close the view, because drag down is neither discoverable nor available to VoiceOver.

## Commit

`feat(ui): open a Photo full screen with zoom and the Photographer credit`

## Comments
