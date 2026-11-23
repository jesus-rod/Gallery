# Instruments Run A (SwiftUI template), 2026-11-23

iPhone 15 Plus (60 Hz), iOS 27.0.1, Release build from Xcode 27.2, live key. Template: SwiftUI instrument, Hangs, Animation Hitches, Time Profiler. 4 min 32 s. Trace kept out of the repo (1.3 GB). Step times from the recorder's notes; numbers exported with `xctrace export` and summarised by script.

| Step | Duration | Hitches | Hitch time ratio | Worst | Main thread busy |
|---|---|---|---|---|---|
| 1 Hero pull and scroll | 27 s | 0 | 0.0 ms/s | n/a | 10% |
| 2 Grid scroll, ~300 images | 59 s | 22 | 6.5 ms/s | 33 ms | 13% |
| 3 Full-screen swipe, ~50 photos | 62 s | 76 (19 GPU) | **20.7 ms/s** | 33 ms | 16% |
| 4 Chrome toggle | 30 s | 3 | 1.7 ms/s | 17 ms | 2% |
| 5 Dismiss drag ×3 | 44 s | 9 (2 GPU) | 3.4 ms/s | 17 ms | 12% |

Apple's guidance: under 5 ms/s good, 5–10 noticeable, over 10 critical.

- One hang: 159 ms "brief unresponsiveness" on the main thread, 10.7 s into step 3, inside SwiftUI view-list building (`DynamicViewList.updateValue`, `_makeViewList`); likely a new Page appended to the pager's `ForEach`.
- Step 3: `FullScreenPhotoView.body` re-evaluates on every page change; each pass copies the whole Stream (`Array(pages.enumerated())`, ~140 ms over the step) and searches `currentIndex` per visible page. The Stream grows while swiping. 19 hitches are GPU-bound, some with 16–31 offscreen passes (ambient glow cross-fade suspected).
- Step 5: the dismiss drag re-evaluates the same body every frame (12% main thread) but stays smooth; no `.drawingGroup()` needed.
- Step 2: cost spread over SwiftUI lazy layout (~2 s inclusive) and `PhotoCell.body` (~340 ms); BlurHash placeholder decode on the main thread totals 56 ms over the whole run.
- Image downsampling: ~12 s CPU, all on background threads.
