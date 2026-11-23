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

## Re-record after the pager fix (`29e524e`), 20:35

Same phone and template, Release, steps 3 and 5 only (91 s; step 3 at 15–60 s, step 5 at 60–91 s by the recorder's notes and main-thread activity). The app symbols were missing; symbolicated a copy with the Release dSYM from DerivedData.

| Step | Run A | Re-record |
|---|---|---|
| 3 Full-screen swipe | 20.7 ms/s; 76 hitches in 62 s (40 app update, 19 GPU, 17 unlabelled); 159 ms hang mid-swipe | **15.9 ms/s**; 43 hitches in 45 s (14 app update, 17 GPU, 12 unlabelled); no hang mid-swipe |
| 5 Dismiss drag | 3.4 ms/s, 9 hitches | 4.2 ms/s, 8 hitches (same, within noise) |

- `FullScreenPhotoView.body` no longer appears in either step (Run A: ~224 ms in step 3, ~180 ms in step 5). Our code in step 3 is now the visible pages' `ZoomablePhotoPage.body` (~80 ms) and the grid cells behind (~66 ms); the rest is UIKit/Core Animation commit and SwiftUI display-list work.
- App-update hitches per second halved (0.65 → 0.31). GPU hitches did not change (0.31 → 0.38 per second) and are now the largest cause: the ambient glow (radius-60 blur of a full-screen upscale, two layers during the 0.35 s cross-fade) is the suspect.
- One 115 ms hang remains, now at the moment full screen opens (`GalleryRootView.openFullScreen`), not mid-swipe.

## Re-record after the glow fix (`645ecad`), 20:48

Same phone, Release, step 3 only (swipe ~50 photos, 5–46 s of a 46 s recording), symbolicated with the matching dSYM.

| Step 3 full-screen swipe | Run A | After pager fix | After glow fix |
|---|---|---|---|
| Hitch time ratio | 20.7 ms/s | 15.9 ms/s | **8.1 ms/s** |
| Hitches per second | 1.23 | 0.96 | 0.48 |
| GPU-bound hitches | 19 in 62 s | 17 in 45 s | 1 (+1 render with GPU) in 41 s |
| Hangs | 159 ms mid-swipe | 115 ms on open | none |

- GPU hitches are gone. Four "expensive render" frames remain with 23–30 offscreen passes; the glow no longer has a filter, so these are likely the chrome's glass buttons.
- What's left is spread over SwiftUI and Core Animation commits; our code is the visible pages' `ZoomablePhotoPage.body` (~80 ms) and the grid cells behind (~64 ms).
