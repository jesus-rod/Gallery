# 06 — Ambient glow without a live blur

Status: done; re-record: step 3 15.9 → 8.1 ms/s, GPU hitches 17 → 1, no hang (look check on device by the user)
Blocked by: 05

After ticket 05, the full-screen swipe still ran at 15.9 ms/s hitch time, and GPU-bound hitches were the largest cause (17 of 43 in 45 s, unchanged by 05). The ambient glow blurred (radius 60, opaque edges) a full-screen upscale of the 32×32 Preview, and the 0.35 s page cross-fade stacked two of them; Run A logged frames with 16–31 offscreen passes.

## Fix

Drop the live blur. The Preview is a BlurHash, already a smooth sum of a few cosines; on screen, radius 60 is about 2 Preview pixels. The glow is now the Preview scaled up with high-quality interpolation and dimmed, so the GPU draws two textured layers during the cross-fade and no filter.

Compared before and after by rendering four real BlurHashes side by side (throwaway test, not committed): the upscale is slightly more defined and a bit more colourful, still soft. If the user prefers the softer look, the fallback is a one-off 2 px blur of the 32×32 Preview on the CPU, cached with it.

## Acceptance

- `swift test` green; lint clean; app builds.
- User checks the look on device with a live key and re-records step 3; GPU hitches compared in the decision log.

## Decision log

- The ambient glow no longer runs a blur filter: it is the 32×32 BlurHash Preview scaled up with high-quality interpolation and dimmed. A radius-60 blur over the full screen, doubled during the page cross-fade, was the largest remaining cause of hitches while swiping (GPU-bound, up to 31 offscreen passes a frame); a BlurHash is already smooth, so the upscale looks almost the same.

## Commit

`perf(ui): draw the ambient glow without a live blur`
