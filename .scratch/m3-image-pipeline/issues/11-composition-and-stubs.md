# 11 — Compose the pipeline, stub images

Status: ready-for-agent
Blocked by: 02–10

Composition root builds the chain from `ImagePipelineConfiguration.default`: image `URLSession` with `urlCache = nil`, `FileImageDataStore` in Caches, eviction to `diskByteLimit` in a background task at launch, `removeAll()` on `UIApplication.didReceiveMemoryWarningNotification`. With `-useStubs`, the remote fetch answers fixture URLs with a bundled image.

## Acceptance
- Live run shows images (manual, needs 12).
- XCUITest with `-useStubs`: first cells report a loaded image.
- No network traffic during XCUITests.
