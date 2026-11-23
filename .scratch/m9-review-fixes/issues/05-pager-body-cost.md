# 05 — Cut the full-screen pager's per-update cost

Status: code done (276 tests, lint, 4 journeys green); waiting on the user's re-record of Run A steps 3 and 5
Blocked by: none

Instruments Run A (`.scratch/m9-photos-polish/instruments-run-a.md`, iPhone 15 Plus, Release) showed the full-screen swipe through ~50 photos at **20.7 ms/s hitch time** (76 hitches, 19 GPU-bound) and one 159 ms hang, against 0–6.5 ms/s everywhere else. Time Profiler: `FullScreenPhotoView.body` re-evaluates on every page change and on every frame of the dismiss drag; each pass copies the whole Stream (`Array(pages.enumerated())`) and runs `currentIndex` (a linear search) once per visible page. The Stream grows while swiping (load more), so the cost grows with it. This was deferred from the swiftui-pro review ("`FullScreenPhotoView.pager` recomputes `currentIndex` per visible page").

## Fix

1. **`PagerWindow`** (pure, tested): built once per body pass from `pages`, `currentID` and the route's Photo. Gives the current Photo and answers `isCurrent(id)` / `loadsFullImage(id)` (current and its two neighbours) from a precomputed set, so the `ForEach` iterates `pages` directly with no copy and no per-page search.
2. **Dismiss drag out of the parent body**: the translation moves from `@State CGSize` in `FullScreenPhotoView` to a small `@Observable` `DismissDrag` that the page writes and only two leaf views read (the pager's offset and the backdrop's fade). Dragging no longer re-evaluates the whole full-screen body.
3. **Hang**: likely the `ForEach` diff over the copied array when a Page is appended mid-swipe; re-check after 1.

## Not in this ticket (decide after the re-record)

The 19 GPU hitches: the ambient glow blurs (radius 60) a full-screen upscale of the 32×32 Preview, and the 0.35 s page cross-fade stacks two of them. If they remain, blur at preview size and scale up instead, and check the look with a live key.

## Tests

`PagerWindowTests`, one at a time: current Photo by id; falls back to the route's Photo when the id isn't in the Stream; neighbours load the full image, farther pages don't; edges (first and last page).

## Acceptance

- `swift test` green; lint clean; app builds; the full-screen journey (`test_openingAPhoto_…`) passes.
- User re-records step 3 (and step 5) of Run A; hitch ratio and hang compared in the decision log.

## Decision log

- The full-screen pager computes its window (current Photo, neighbours that load the full image) once per update and iterates the Stream without copying it; the dismiss-drag offset lives in a small observable model read only by the views that move, so dragging no longer re-evaluates the full-screen view. Measured: before, 20.7 ms/s hitch time over a 50-photo swipe on iPhone 15 Plus; after, see the re-record.

## Commit

`perf(ui): stop the full screen pager rebuilding on every update`
