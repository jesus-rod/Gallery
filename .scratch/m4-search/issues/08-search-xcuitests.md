# 08 — XCUITests: search end to end

Status: ready-for-agent
Blocked by: 07

Three acceptance tests in the existing `GalleryAppUITests`, launched with `-useStubs` (fixtures from ticket 06). No production code changes, unless a test exposes a bug; then fix it in this ticket and say so in the commit body.

## Files

- Edit: `AppUITests/GalleryAppUITests.swift`

## Shape

Add one helper next to `launchWithStubs()`:

```swift
@MainActor
private func submitSearch(_ query: String, in app: XCUIApplication) {
    let field = app.searchFields.firstMatch
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText(query + "\n")
}
```

Clearing the field is how the tests leave search: tap the field and type `String(repeating: XCUIKeyboardKey.delete.rawValue, count: query.count)`. The Cancel button clears the field too, so it goes through the same `onChange` → `cancelSearch()` path, and its label differs between iOS versions, so the tests do not rely on it.

## Acceptance

Each bullet is one test:
- `test_submittingAQuery_showsItsSearchResults`: wait for `app.images["Fixture photo 1"]`; `submitSearch("cats")`; `app.images["Cat fixture photo 1"]` appears within 5 s; `app.images["Fixture photo 1"].exists` is false (the hidden feed is out of the accessibility tree).
- `test_clearingTheQuery_returnsToTheFeedAtTheSameScrollPosition`: swipe up the `photo-grid` until `app.images["Fixture photo 31"]` exists (same loop as `test_scrollingToTheEnd_loadsTheNextPage`); `submitSearch("cats")`; wait for "Cat fixture photo 1"; clear the field; `app.images["Fixture photo 31"]` exists within 5 s and "Cat fixture photo 1" no longer exists.
- `test_searchingWithNoResults_showsTheQueryInTheEmptyState`: `submitSearch("zzzz")`; `app.staticTexts["No photos for “zzzz”"]` appears within 5 s.
- All existing UI tests still pass: `xcodebuild test -project Gallery.xcodeproj -scheme GalleryApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GalleryAppUITests`.

## Decision log

Nothing new.

## Commit

`test(app): cover search, clearing and empty results on fixtures`.
