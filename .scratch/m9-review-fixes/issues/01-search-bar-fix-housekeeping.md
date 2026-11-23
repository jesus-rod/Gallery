# 01 — Housekeeping for the full-screen-after-search fix

Status: ready-for-agent
Blocked by: none

`3760214` fixed the back button and title sitting 54 pt lower when a Photo is opened while a search is active. Cause: an active `searchable` keeps an empty navigation bar over the pushed full-screen view even though it hides its toolbar, so the chrome's top safe area includes the bar. Fix: `GalleryRootView` measures the window's top inset on the `NavigationStack` (`onGeometryChange` of `safeAreaInsets.top`) and passes it to `FullScreenPhotoView`, whose chrome ignores the top container safe area and pads by that inset.

The commit broke two repo rules: it added a `///` doc comment and no decision-log line.

## Files

- Edit: `Gallery/Sources/GalleryUI/FullScreen/FullScreenPhotoView.swift` (remove the two-line `///` comment above `topInset(_:)`)
- Edit: `docs/decision-log.md` (create `## Review fixes (M9)` at the end)

## Decision log

- An active search keeps an empty navigation bar over full screen even though full screen hides it, which pushed the back button and title down by the bar's height. The chrome now lays out against the window's top inset, measured on the `NavigationStack`, instead of its own safe area. Rejected: `.searchPresentationToolbarBehavior(.avoidHidingContent)` (fixes full screen but shows a ghost large title and loses the feed's scroll position when the Query is cleared), dismissing the search before the push (clears the Query), forcing an inline title (no effect).

## Acceptance

- No comment left in the file; `swift test` green; lint clean.

## Commit

`docs: log the full screen fix after a search`
