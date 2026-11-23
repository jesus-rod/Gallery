# SPM modules, with the logic modules also building for macOS

The code lives in a local Swift package split into `GalleryCore` (domain, Streams, API mapping, Offline feed store; Foundation only), `GalleryImageLoading` (the pipeline; Foundation, ImageIO and CoreGraphics only), and `GalleryUI` (SwiftUI). A thin Xcode app target is the composition root. Core and ImageLoading declare macOS as well as iOS support, solely so `swift test` runs them on the Mac with no simulator. That keeps the TDD loop fast, works in CI, and enforces that no UIKit or SwiftUI leaks into them.

## Consequences

- Platform-specific imports in Core or ImageLoading break the macOS build. That is the point: the build is the guard.
- Core and ImageLoading do not depend on each other; only UI and the app target see both.
