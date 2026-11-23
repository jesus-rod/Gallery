# 06 — XCUITests for the Full-screen view

Status: ready-for-agent
Blocked by: 05

End-to-end checks on fixtures (`-useStubs`). The stub image client routes on the URL's last path component, so the full-screen Rendition (built from `raw` with `w`, `dpr`, `q`, `fm`) is answered without any change. No production code should change; if a test needs one, note why in the Comments.

## Files

- Edit: `AppUITests/GalleryAppUITests.swift`

## Fixture facts

- First Editorial Photo: Caption "Fixture photo 1", Photographer "Fixture Photographer 2" (read from `App/Stubs/Fixtures/editorial-page-1.json`; check again before asserting).
- First "cats" Photo: Caption "Cat fixture photo 1".

## Tests

- `test_tappingAPhoto_opensItFullScreenWithItsCaptionAndCredit`: tap `app.images["Fixture photo 1"]` → `app.images["full-screen-photo"]` exists with label "Fixture photo 1"; the element `photo-credit` contains "Fixture Photographer 2".
- `test_theFullScreenView_loadsTheFullImage`: after opening, the `full-screen-photo` value becomes empty (same predicate as `test_launch_loadsTheImagesOfTheFirstCells`).
- `test_closingTheFullScreenView_returnsToTheGridAtTheSameScrollPosition`: scroll until "Fixture photo 31" exists, tap it, tap `full-screen-close` (tap the photo first if the overlay is hidden), then "Fixture photo 31" exists and is hittable and `full-screen-photo` is gone.
- `test_tappingASearchResult_opensItFullScreen`: submit "cats", tap "Cat fixture photo 1" → `full-screen-photo` label "Cat fixture photo 1".

Add a small `openFullScreen(_ caption:in:)` helper next to `submitSearch`.

## Acceptance

- `xcodebuild test … -only-testing:GalleryAppUITests`: 10 tests, 0 failures. Lint clean.

## Decision log

Nothing new.

## Commit

`test(app): cover opening, loading and closing the Full-screen view`
