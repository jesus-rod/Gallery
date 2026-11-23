# Instruments runbook (M9 ticket 08, M8 ticket 07 performance part)

For whoever records: the user plus Claude Desktop. The output feeds the README "Performance" table and the decision log.

## Who does what

Claude Desktop (computer use) drives the Mac: Xcode, Instruments, reading numbers, screenshots, saving files. **It can't touch the iPhone.** The user does every gesture on the phone when Claude Desktop says "go", and says "done" at the end of each step. Claude Desktop marks each step's start and end time (or drops a flag in the timeline) so the numbers can be split per step.

## Before you start

1. Real iPhone, plugged in, unlocked, Developer Mode on. Not the simulator: its hitch and memory numbers don't mean much.
2. `Config/Secrets.xcconfig` holds a real Unsplash access key (it's there; don't print it, don't screenshot it).
3. **Request budget: 50 requests an hour.** Scrolling 500 images is about 17 requests. The plan below uses about 35–40 for the session. Don't redo runs on a whim. If the app shows the rate-limited message, stop and wait an hour.
4. Open `Gallery.xcodeproj`, scheme **GalleryApp**, destination = the iPhone. The scheme's Profile action already builds **Release** and passes **no** launch arguments (so no `-useStubs`): that's what we want.
5. Product › Profile (⌘I). Xcode builds and opens Instruments with the template picker.
6. Make a folder `~/Desktop/gallery-instruments/` for traces. Traces are big; **don't** put them in the repo. Screenshots go in the repo, in `docs/instruments/` (create the folder).

## Run A: SwiftUI template (scrolling, hero, full screen, dismiss)

Template: **SwiftUI** (on Xcode 26+ it bundles the SwiftUI instrument, Time Profiler, Hangs and Animation Hitches). If Animation Hitches isn't in it, add it from the library (+) before recording.

Record, then the user does, in order (Claude Desktop notes the time of each):

1. **Hero**: on the feed, pull down on the hero three times, then scroll up past it slowly and back.
2. **Grid scroll**: fling through the feed until about 300 images are loaded (about 10 pages; the spinner footer shows paging), then back to the top quickly.
3. **Full screen swipe**: tap a photo, swipe left through about 50 photos at a natural pace.
4. **Chrome toggle**: tap the photo 6 times (controls hide and show, the glow fades to black and back).
5. **Dismiss drag**: drag the photo down slowly halfway, let it snap back; then drag down to dismiss. Repeat on 3 different photos.

Stop. Save as `~/Desktop/gallery-instruments/A-swiftui.trace`.

Read and write down:

- **Animation Hitches**: number of hitches and the hitch time ratio (ms/s) for each step 1–5. Note the worst single hitch and which step it was in.
- **Hangs**: any hang, with duration and step.
- **Time Profiler**: select the dismiss-drag range (step 5). Main thread %, and the top 5 heaviest symbols with "Hide System Libraries" off and on. Same for the grid scroll range (step 2). Look specifically for: image decoding (`CGImageSource…`, `BlurHash`) on the **main** thread (shouldn't be there), `blur`/`GaussianBlur`/`CABackdrop` during the dismiss drag, and `CodableFeedStore`/`JSONEncoder` (the Offline feed saves each page during step 2).
- **SwiftUI instrument**: in the grid scroll range, the views with the most body updates (top 5, with counts), and whether `PhotoCell`-type views update more than once each per appearance. In the full-screen range, the same for the pager.

Screenshots (PNG, into `docs/instruments/`):
- `hitches.png`: the Animation Hitches track over the whole run, steps visible.
- `time-profiler-dismiss.png`: call tree for step 5.
- `swiftui-scroll.png`: SwiftUI body-update summary for step 2.

## Run B: Allocations (memory stays bounded)

Template: **Allocations**. Kill the app first so the run starts cold.

Record, then the user does:

1. Scroll the feed until about 500 images are loaded (about 17 pages), steadily.
2. Scroll back up to the top.
3. Open and close 20 photos from the grid (tap, wait for the sharp image, close with the Close button).
4. Open one photo and swipe through 200 photos in full screen.
5. Close. Wait 10 seconds without touching anything.

Stop. Save as `~/Desktop/gallery-instruments/B-allocations.trace`.

Read and write down:

- **All Heap & Anonymous VM**, persistent bytes, at the end of each step 1–5, and the peak.
- Is memory **flat during step 4** (should be: only the current page and its neighbours hold full-size images)? Give the start and end value of step 4.
- During step 3: when you closed a photo, did grid cells that were visible go back to the blurry placeholder and reload? (Ask the user; it's a visual check.) This answers "do full-screen images push grid images out of the memory cache".
- Mark Generation (the flag button in Allocations) at the start of step 3 and at the end of step 5: the generation's growth tells if anything leaks across open/close.

Screenshot: `allocations.png`, the whole timeline with the step marks.

## Run C (only if Run A shows hitches in the dismiss drag)

If step 5 in Run A had hitches, tell the user; the agent will try `.drawingGroup()` on the ambient backdrop and you'll record step 5 again with Animation Hitches only, then compare. Don't change code yourself.

## Hand back

Write `~/Desktop/gallery-instruments/results.md` with:

- Device model, iOS version, Xcode version, date.
- Run A: the numbers above per step, the top symbols, and anything surprising.
- Run B: memory per step, peak, the step 4 start/end, the step 3 visual answer, generation growth.
- The list of screenshots saved in `docs/instruments/`.

Then the user tells the agent in Claude Code where `results.md` is. Don't edit the README or decision log; the agent writes those up.
