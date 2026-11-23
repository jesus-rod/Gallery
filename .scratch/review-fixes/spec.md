# Review fixes for M3 and M4

Status: tickets ready

## Goal

Fix the bugs that the M3 + M4 code review (standards and spec axes, range `c2852ce...d01f619`) confirmed, before M5 ticket 05 changes the cell. The user agreed this cut on 2026-11-23. Smells (duplicated closures and cache entries, URL + pixel size in three shapes, Query as `String`, repeated `StreamState` switches) and the double decode above the memory cache are deferred to the M8 review sweep.

## Findings fixed here

| # | Finding | Ticket |
|---|---|---|
| 1 | A new Query or Cancel only cancels the search's first Page. Its load more and Retry keep running and spend the Request budget (spec: "Any in-flight search is cancelled and its result discarded"). | 01 |
| 2 | Re-submitting a Query whose first Page failed does nothing; only Retry works. | 02 |
| 3 | `PhotoCell`'s `State(initialValue: PhotoImageModel(...))` builds a model, and looks up the Preview on the main thread, on every parent redraw; all but the first are thrown away. | 03 |
| 4 | The Preview is removed in the same animation that inserts the image, so they cross-fade and the grey cell fill shows through. Spec: "image fades in over the Preview". | 03 |
| 5 | M3 ticket 10's "Cancelled load leaves the state unchanged" has no test. | 03 |
| 6 | Portrait Photos taller than 3:1 decode narrower than the cell (the 3:1 cap also limits `maxPixelSize`), so they are upscaled. | 04 |
| 7 | `FileImageDataStore.retrieve` throws when updating the last-used date fails, after reading the data, so a disk hit becomes a network fetch. | 05 |
| 8 | Six XCUITests where the roadmap settles on 2–3; each relaunches the app. Added by the user after the review (testing pyramid). | 06 |

## Rules for the implementer

Same as `.scratch/m5-full-screen/spec.md` "Rules for the implementer" (TDD, Swift Testing, `makeSUT` + leak tracking, no code comments, commands, own `-derivedDataPath`, explicit `git add` paths, never stage the Xcode project/scheme rewrites, one commit per ticket authored by the user with no attribution). Decision-log lines go under a new `## Review fixes (M3, M4)` heading at the end of `docs/decision-log.md`, created by ticket 01.
