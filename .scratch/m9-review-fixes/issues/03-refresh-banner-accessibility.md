# 03 — Refresh banner respects Reduce Motion and is announced

Status: ready-for-agent
Blocked by: 01

The refresh-error banner (`RefreshErrorBanner`, shown in `GalleryRootView`'s top `safeAreaInset`) slides in with `.move(edge: .top).combined(with: .opacity)` under `.animation(.default, value: viewModel.refreshError)`. Every other animation goes through `Design.Motion.*(reduceMotion:)`; this one ignores Reduce Motion. It also dismisses itself after 3 s, and VoiceOver users get no announcement, so they may never know the refresh failed.

## Files

- Edit: `Gallery/Sources/GalleryUI/DesignSystem/Design.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/RefreshErrorBanner.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryRootView.swift`
- Edit: `docs/decision-log.md`

## Shape

- `Design.Motion.banner(reduceMotion:) -> Animation?`: `nil` under Reduce Motion, otherwise the current default-like ease (`.easeInOut(duration: 0.25)` is fine).
- `GalleryRootView`: `.animation(Design.Motion.banner(reduceMotion: reduceMotion), value: viewModel.refreshError)`.
- `RefreshErrorBanner`: read `accessibilityReduceMotion`; transition `.opacity` under Reduce Motion, else today's move + opacity.
- On appear, post `AccessibilityNotification.Announcement(error.title).post()` (iOS 17 API) before the 3 s dismissal task.

## Tests

The `Design.Motion` helpers are untested today and the rest is view wiring; no unit test is required. Verify by hand: run the offline-feed journey (`test_launchingOffline_…`, it triggers a failed refresh) on iPhone 17 Pro `B24D2789-AEFD-4872-BECA-40CCEBED0913` and confirm it still passes. Optionally toggle Reduce Motion in the simulator's Accessibility settings and screenshot the banner.

## Acceptance

- `swift test` green; lint clean; app builds; the offline journey passes.

## Decision log

- The refresh-error banner follows Reduce Motion (fade only, no animation driver) like the rest of the app, and is announced to VoiceOver because it disappears by itself after 3 s.

## Commit

`fix(ui): respect Reduce Motion and announce the refresh banner`
