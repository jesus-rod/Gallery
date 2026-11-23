# 06 — Merge the XCUITests into one test per journey

Status: done
Blocked by: 01–05 (run after the other review fixes; ticket 03 runs the UI tests)

The roadmap settles on "2–3 XCUITest acceptance tests", but M2–M4 left six, each relaunching the app. Merge them into one test per user journey and leave the details to unit tests, which already cover them.

## Files

- Edit: `AppUITests/GalleryAppUITests.swift`
- Edit: `docs/decision-log.md`

## From six tests to two

| Today | After |
|---|---|
| `test_launch_showsTheFirstPageOfTheEditorialFeed`, `test_launch_loadsTheImagesOfTheFirstCells`, `test_scrollingToTheEnd_loadsTheNextPage` | `test_browsingTheEditorialFeed_showsLoadedPhotosAndPagesOnScroll`: first cell "Fixture photo 1" appears, its value becomes empty (image loaded, same predicate as today), swipe until "Fixture photo 31" exists. |
| `test_submittingAQuery_showsItsSearchResults`, `test_clearingTheQuery_returnsToTheFeedAtTheSameScrollPosition` | `test_searching_showsResultsAndClearingReturnsToTheFeedWhereItWas`: scroll to "Fixture photo 31", submit "cats", "Cat fixture photo 1" shows and "Fixture photo 1" does not, clear the field, "Fixture photo 31" is back and "Cat fixture photo 1" is gone. |
| `test_searchingWithNoResults_showsTheQueryInTheEmptyState` | Removed. Empty Search results are covered by `GalleryViewModelTests` (`.loaded(photos: [], footer: .end)`) and the "No search results" `#Preview`. |

Keep the `submitSearch` and `launchWithStubs` helpers; add a `scrollUntil(_:in:)` helper if both journeys need the swipe loop. Each step keeps its own `XCTAssert…` with a message naming the step, so a failure says which part of the journey broke. No production code changes.

If M5 ticket 06 has already landed, leave its full-screen journey test as is (three tests in total).

## Acceptance

- `xcodebuild test … -only-testing:GalleryAppUITests` passes with two tests (three if M5's journey exists). Lint clean. `swift test` untouched and green.

## Decision log

- One XCUITest per user journey (feed, search, full screen), with each step asserted. Details live in unit tests, because every XCUITest relaunches the app and costs seconds. The six M2–M4 UI tests became two.

## Commit

`test(app): merge the UI tests into one per journey`
