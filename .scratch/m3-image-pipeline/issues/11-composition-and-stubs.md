# 11 — Compose the pipeline, stub images

Status: done
Blocked by: 02–10

Composition root builds the chain from `ImagePipelineConfiguration.default`: image `URLSession` with `urlCache = nil`, `FileImageDataStore` in Caches, eviction to `diskByteLimit` in a background task at launch, `removeAll()` on `UIApplication.didReceiveMemoryWarningNotification`. With `-useStubs`, the remote fetch answers fixture URLs with a bundled image.

## Acceptance
- Live run shows images (manual, needs 12).
- XCUITest with `-useStubs`: first cells report a loaded image.
- No network traffic during XCUITests.

## Comments

- `ImagePipeline` (app target) owns the decorator chain from `ImagePipelineConfiguration.default`: 100 MB memory, 200 MB disk, prefetch 9 ahead, 32 px Previews, q=75.
- Disk eviction runs in a detached background task when the root view first appears; memory warnings clear the memory cache through `onReceive`.
- `StubImageHTTPClient` maps `images.unsplash.com/fixture-NN` to one of four bundled gradient JPEGs; anything else gets a 404. Verified on the iPhone 17 Pro simulator: the grid shows the gradients, center-cropped.
- The live run with a real key is still ticket 12.
