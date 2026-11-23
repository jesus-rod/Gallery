# M0 — Scaffold

Status: done

## Goal

A runnable empty app and a test loop that runs without a simulator, so every later milestone starts from green.

## Scope

- Repo hygiene: `.gitignore` for Xcode, SPM, macOS and secrets; `.swift-format` config.
- Local Swift package `Gallery` with `GalleryCore`, `GalleryImageLoading`, `GalleryUI` and one Swift Testing target each (ADR-0002).
- Thin Xcode app target `GalleryApp` that depends on the package and is the composition root.
- Unsplash access key read from a gitignored `Secrets.xcconfig` into Info.plist; a committed `Secrets.example.xcconfig`.
- CI: GitHub Actions running `swift test`.
- README skeleton with the brief's required sections.

## Out of scope

Any feature logic. UI test target (added in M2 with the stubbed launch path).

## Done when

- `swift test` passes from `Gallery/`.
- `xcodebuild build` of the app scheme succeeds for an iOS simulator.
- `git status` shows no `Secrets.xcconfig`, `.build/`, `DerivedData/` or `.DS_Store`.
- Neither the company names nor the key appear in any committed file.
