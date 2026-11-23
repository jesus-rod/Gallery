# Own image pipeline instead of an image-loading library

Smooth scrolling through hundreds of Photos and avoiding duplicated work are the heart of this app, so we build the pipeline ourselves instead of adopting Nuke or Kingfisher. It is one `ImageDataLoader` abstraction with each concern as a composable decorator: remote fetch, in-flight request deduplication, a disk cache of raw bytes, and a memory cache of decoded, downsampled images. Prefetching and cancellation are driven by the grid. We also decode BlurHash Previews with our own small decoder rather than a dependency.

## Considered Options

- **Nuke / Kingfisher**: mature and fast, but their defaults would do the core work, and we could not explain or measure each layer.
- **`AsyncImage` + `URLCache`**: no downsampling, no deduplication, no control over eviction, and known reload issues inside lazy grids.

## Consequences

- We own correctness for cancellation that is shared between callers (a cancelled prefetch must not cancel a load another caller is waiting on) and for cache eviction.
- The image `URLSession` runs with `urlCache = nil` so images are not cached twice.
- Each layer's impact is measured with Instruments and reported in the README.
