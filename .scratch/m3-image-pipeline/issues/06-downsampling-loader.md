# 06 — Downsampling image loader

Status: done

`DownsamplingImageLoader(dataLoader:)` conforming to `ImageLoader`: ImageIO `CGImageSourceCreateThumbnailAtIndex` with `kCGImageSourceThumbnailMaxPixelSize`, `CreateThumbnailFromImageAlways`, `CreateThumbnailWithTransform`, `ShouldCacheImmediately`, and `ShouldCache: false` on the source.

## Acceptance
- 400×200 PNG, max 100 → 100×50.
- Smaller than max → never upscaled.
- Undecodable data → `invalidImageData`.
- Data loader error rethrown.
