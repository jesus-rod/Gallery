# 10 — Cell image: Preview, Rendition, fade

Status: done
Blocked by: 01, 07, 08, 09

`PhotoImageModel` (`@Observable @MainActor`) per cell in `GalleryUI`: `state` is `.preview(CGImage?)` then `.image(CGImage)`. `PhotoCell` measures its size with `GeometryReader` (or `onGeometryChange`), builds the grid Rendition URL, and loads in `.task(id: url)`. `PhotoGrid` asks the prefetcher for items i+1…i+k on appear.

## Acceptance
- Initial state is the cached Preview (nil without BlurHash).
- Successful load → `.image`; failure → stays on Preview.
- Cancelled load leaves the state unchanged.
- Image fades in over the Preview (view, `#Preview`).
- No leak.

## Comments

- GalleryUI owns `PhotoImages` (preview, image, prefetch closures plus the prefetch distance) and `ImageSize`. It never sees URLs or caches; the composition root builds the closures from the pipeline and `UnsplashRendition.grid`.
- `SquareGrid` measures its width once with `onGeometryChange` and passes the cell side to its content, so cells and prefetching share one exact pixel size.
- The window ahead is a pure function, `prefetchWindow(after:in:distance:)`, with its own tests.
- While only the Preview shows, a cell reports the accessibility value "Loading". VoiceOver users hear it, and the XCUITest waits for it to clear.
- `#Preview`s get generated solid-colour images that fade in after a random delay.
