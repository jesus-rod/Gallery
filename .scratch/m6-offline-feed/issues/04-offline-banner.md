# 04 — Offline banner

Status: ready-for-agent
Blocked by: 03

No unit tests: logic-free view. `#Preview` and the ticket 06 journey cover it.

## Files

- Edit: `Gallery/Sources/GalleryUI/Gallery/StateViews.swift` (new `OfflineBanner`)
- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryRootView.swift`
- Edit: `Gallery/Sources/GalleryUI/Gallery/GalleryPreviews.swift` (`#Preview("Offline feed")`)
- Edit: `Gallery/Sources/GalleryUI/Localizable.xcstrings` (catalog format, sorted, with comments)

## Shape

- Shown at the top of the feed (inside the feed content, so it hides with the feed during search) while `viewModel.offlineFeedReason != nil`. Persistent, not auto-dismissed. `.thinMaterial` capsule like `RefreshErrorBanner`, with the reason's existing `systemImage` (from `LoadError` in `StateViews.swift`). Decide the text with `reason == .offline ? … : …`, not an exhaustive `switch`, so a new `LoadError` case (M7 adds `invalidKey`) needs no change here.
- Text: `.offline` → "You're offline · Showing saved photos"; others → "Showing saved photos". One accessibility element, identifier `offline-banner`. Dynamic Type: wraps, no truncation.
- The refresh error banner still shows above it on a failed refresh.

## Strings

"You're offline · Showing saved photos", "Showing saved photos".

## Commit

`feat(ui): label the Offline feed with a banner`
