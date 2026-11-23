# 05 — Grid views

Status: ready-for-agent
Blocked by: 02, 03, 04

`GalleryRootView` renders `feed`: skeleton grid while `loading`, full-screen error with retry on `failed` (own copy for `offline` and `rateLimited`), `PhotoGrid` when `loaded`. `PhotoGrid` is a `LazyVGrid` of square cells (2 columns compact, 3 regular, ADR 0005), each with a neutral fill and the Caption as VoiceOver label, a footer for `loading`/`failed` (retry button), and `.refreshable`. Accessibility identifiers for XCUITests. `#Preview`s for each state. No tests; views hold no logic.
