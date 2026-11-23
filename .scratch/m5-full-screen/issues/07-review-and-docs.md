# 07 — Review, docs, roadmap and device check

Status: agent part done; human part ready-for-human
Blocked by: 06

Close M5.

## Agent part

1. Quick essential-feed review of the M5 diff (first M5 commit's parent `..HEAD`): UI depends only on `PhotoImages` closures; `UnsplashRendition` and `UnsplashAttribution` used only in the composition root and the credit view; no code comments; every new SUT through `makeSUT` with leak tracking; iOS 18 APIs only behind `#available`. Write the findings as `## Review notes` in `spec.md`.
2. `spec.md`: `Status: done`.
3. `.scratch/roadmap.md`: M5 done, M6 next ("write spec"). In Settled decisions, replace "Full screen uses `regular`, with the cached grid image underneath" with the sized-from-`raw` rule, and in the UI bullet replace "cross-fade on iOS 17" with "standard push on iOS 17" and the step 0 dismiss outcome. Replace "Carried into M5" with "Carried into M6", keeping what is still open.
4. `CONTEXT.md`: no new terms expected; add one only if the code introduced a domain word.
5. Append to M3/12's Comments: the live run now also covers opening a Photo full screen (no API request).

## Human part (the user, on device or simulator)

Record the results in this ticket's Comments.
- ~~Step 0 of ticket 05~~ done on device: our drag dismisses on both versions (see ticket 05 Comments).
- Gesture feel on iOS 18+: pinch, double tap, pan when zoomed, swipe down to close, zoom transition back into the right cell (feed and Search results).
- iOS 17 simulator, if a runtime is installed: standard push, our drag to dismiss.
- Rotate while full screen: the image stays, then sharpens.
- Instruments, Allocations: open and close about 20 Photos, then scroll the grid. Does memory stay bounded, and do visible grid cells reload (full-screen images evicting grid images from the shared memory cache)? If they do, open a ticket for a separate small full-screen cache.
- Live key: open one Photo full screen during the M3/12 run.

## Decision log

Only what the review or device check changes.

## Commit

`docs(scratch): mark M5 done and carry review notes into M6`

## Comments

- Agent part done: review notes in `spec.md` (no code changes needed; two M7 items and one M8 item carried), spec `Status: done`, roadmap updated (M5 done, M6 next, Settled decisions, "Carried into M6"), M3/12 comment added. `CONTEXT.md` unchanged: no new domain words (`ZoomTransform`, `ContentFit` and `FullScreenRoute` are implementation names; "Full-screen view" already exists).
