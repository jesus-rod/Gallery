# 06 — XCUITest for the Full-screen view journey

Status: done
Blocked by: 05

One end-to-end journey on fixtures (`-useStubs`), not one test per detail. The project keeps one XCUITest per user journey (roadmap: "2–3 XCUITest acceptance tests"); each one relaunches the app and costs seconds, while the details are already unit tested (`FullScreenImageModel` covers which image shows when, `ZoomTransform` the gestures maths, `UnsplashAttribution` the links). Opening from Search results goes through the same route code as the feed, so it gets no separate UI test.

The stub image client routes on the URL's last path component, so the full-screen Rendition (built from `raw` with `w`, `dpr`, `q`, `fm`) is answered without any change. No production code should change; if the test needs one, note why in the Comments.

## Files

- Edit: `AppUITests/GalleryAppUITests.swift`

## Fixture facts

- First Editorial Photo: Caption "Fixture photo 1", Photographer "Fixture Photographer 2" (read from `App/Stubs/Fixtures/editorial-page-1.json`; check again before asserting).

## Test

`test_openingAPhoto_showsItFullScreenWithItsCreditAndClosesBackToTheGrid`:
1. Launch with stubs; wait for `app.images["Fixture photo 1"]`.
2. Tap it → `app.images["full-screen-photo"]` exists with label "Fixture photo 1"; the element `photo-credit` contains "Fixture Photographer 2".
3. Tap `full-screen-close` (tap the photo first if the overlay is hidden) → `full-screen-photo` is gone and "Fixture photo 1" exists and is hittable.

## Acceptance

- `xcodebuild test … -only-testing:GalleryAppUITests`: every UI test passes, one more than before. Lint clean.

## Decision log

- The Full-screen view gets one XCUITest for the whole journey (open, credit, close); loading order, zoom maths and links are unit tested.

## Commit

`test(app): cover opening and closing the Full-screen view`

## Comments

- Passes with the other two journeys (3 UI tests, `** TEST SUCCEEDED **`). It caught the Close button not responding; fixed in `FullScreenPhotoView` (gestures on a layer under the overlay), so the test needed no production change of its own. The decision-log line is already covered by "One XCUITest per user journey (feed, search, full screen)".
