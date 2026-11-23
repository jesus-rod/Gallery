# 08 — Snapshot matrix on the iOS simulator

Status: done (iPhone Duo included: unfolded display from the simulator profile, safe areas estimated; iPad recorded in portrait)

The user wants snapshots of the design system elements, the main components, and the main screens on several devices, all in light and dark. Device-sized snapshots need iOS (size classes, safe areas, iOS fonts), so the snapshot suite moves from macOS to the iOS simulator (the user chose this). `swift test` on macOS stays the fast logic run.

## Shape

- Keep the suite in `Gallery/Tests/GalleryUITests/`, but guard it with `#if os(iOS)` instead of `#if os(macOS)`, so `swift test` on macOS compiles it to nothing. Split it into files by kind: `DesignSystemSnapshotTests.swift`, `ComponentSnapshotTests.swift`, `ScreenSnapshotTests.swift`, plus a helper file (`SnapshotSupport.swift`) for appearances, devices, hosting and fixture images.
- Render with `UIHostingController` and swift-snapshot-testing's `.image(...)` strategies, with `traits: UITraitCollection(userInterfaceStyle: .light / .dark)`. Use `perceptualPrecision: 0.98` (and `precision: 0.99`) so CI simulators with slightly different rendering still pass.
- **Devices** in ONE list in `SnapshotSupport.swift`, so adding a device is one line. Each entry is a name plus a `ViewImageConfig` (size, safe area, traits including size class and display scale):
  - `iPhoneSE`: the library's `.iPhoneSe` config (375 × 667 pt).
  - `iPhone17`: custom, 402 × 874 pt, safe area top 62 / bottom 34, @3x, compact width, regular height.
  - `iPad`: the library's `.iPadPro11` config (834 × 1194 pt, regular/regular).
  - The user mentioned a new "iPhone Duo"; its dimensions are unknown. Leave no placeholder: the list is easy to extend later.
- **Screens** (each × every device × light/dark), built from `GalleryRootView` / `FullScreenPhotoView` with stubbed closures and solid or two-tone fixture `CGImage`s returned by `cachedImage` so images show on the first frame:
  1. Feed loaded (30 Photos with mixed captions, including a long one).
  2. Feed loading (skeleton).
  3. Feed first-page error (`.offline`).
  4. Offline feed (saved Photos + Offline banner).
  5. Search results (Query "cats").
  6. Empty search.
  7. Full screen (overlay visible).
  Pre-load the view model (`await viewModel.load()`, `await viewModel.search("cats")`) before snapshotting; the view's own `.task` reloading the same stubbed data later is harmless. Use the `.wait(for: 0.3, on: …)` strategy for screens so `onGeometryChange`, `.task` and first layout settle (FullScreenPhotoView sizes its image from `onGeometryChange`; without waiting it renders an empty frame). If navigation bars, the search field or materials don't render, try `drawHierarchyInKeyWindow: true`.
- **Components** (light/dark, sized to fit or a fixed sensible size): `PhotoCell` (Preview only; loaded image with Caption; long Caption truncating), `OfflineBanner` (`.offline` and `.rateLimited` text variants), `RefreshErrorBanner`, `LoadErrorView` for all four errors, `EmptySearchView`, `FooterView` (`.loading`, `.failed(.offline)`), `PhotoCreditView`, `FullScreenCaptionLayer`, `FullScreenCloseLayer`.
- **Design system** (light/dark): `Scrim` over a solid colour, `.bannerStyle()` on a short and a two-line text, and a token sheet view built in the test (a few swatches/boxes showing `Design.Spacing` values, the hit target and the opacities) so a token change shows up as a diff.
- Delete the old macOS snapshot images and `SnapshotTests.swift`; re-record everything on the pinned simulator **iPhone 17 Pro (id `B24D2789-AEFD-4872-BECA-40CCEBED0913`)**: `cd Gallery && xcodebuild test -scheme Gallery-Package -destination 'id=…' -derivedDataPath <own dir> -only-testing:GalleryUITests` (record missing, then run again and see them pass). Check `git status` image sizes: keep the whole `__Snapshots__` folder reasonable (if iPad images are huge, it's fine to use a smaller iPad config such as `.iPadMini`).
- CI (`.github/workflows/ci.yml`): add a step after `swift test` running the package tests on the same simulator choice the UI-test step uses (`xcodebuild test -scheme Gallery-Package -destination "id=$DEVICE_ID"` from `Gallery/`).
- README "Testing" section: update the snapshot line (count, devices, light/dark, iOS simulator, the record command). Decision log line under `## M8 — Review sweep`.

## Acceptance

- `cd Gallery && swift test` green on macOS (snapshots compiled out).
- Package tests on the iOS simulator green twice in a row with recorded images; app UI tests still green; lint clean.
- Every recorded image looked at once: no blank frames, no missing images, correct column count per device (2 on iPhones, 3 on iPad).

## Commit

`test(ui): snapshot the design system, components and screens per device on iOS`
