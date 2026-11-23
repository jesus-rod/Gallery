# swiftui-performance

Status: done

swiftui-pro review of GalleryUI focusing on body updates, identity, observation scope and image work on the main thread; fix confirmed findings.

## Comments

`swiftui-pro` review (performance, views, data references) on 2026-11-23.

Fixed:
- Full-screen overlay rebuilt on every gesture frame → `FullScreenCloseLayer` and `FullScreenCaptionLayer` with value inputs only (`87cdb50`).
- Caption computed twice per cell body → once in `init`; `PhotoGrid.swift` and `StateViews.swift` split to one type per file (`5af99ac`).
- Found while adding the visible Caption: Preview and image sized against each other in one `ZStack` → `Image.filling()` (`8cf7399`).

Checked, fine: `@Observable` models are `@MainActor`; `@State` private and owned; `LazyVGrid` with stable `ForEach` ids; async work in `.task(id:)`, cancelled on disappear; no `AnyView`; no `Binding(get:set:)`; view inits do no work (models memoise lazily).

For the user's Instruments run: the BlurHash Preview decodes on the main thread on a cell's first read (32 × 32, cached by hash, roughly 0.1 ms); each `PhotoCell` still re-evaluates when the grid's footer changes, because its `onOpen` closure can't be compared.
