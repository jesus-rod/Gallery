# 03 — App target and access-key configuration

Status: done
Blocked by: 02

Add `Gallery.xcodeproj` with an iOS 17 app target `GalleryApp` linking the package's `GalleryUI`, `GalleryCore` and `GalleryImageLoading`. Build settings come from `Config/Base.xcconfig`, which optionally includes the gitignored `Config/Secrets.xcconfig`. Info.plist exposes `UnsplashAccessKey = $(UNSPLASH_ACCESS_KEY)`. The app shows a placeholder screen.

## Acceptance

- `xcodebuild -scheme GalleryApp -destination 'generic/platform=iOS Simulator' build` succeeds with and without `Secrets.xcconfig` present.
- `Config/Secrets.example.xcconfig` is committed; `Config/Secrets.xcconfig` is ignored.
