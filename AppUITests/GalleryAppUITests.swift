import XCTest

final class GalleryAppUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func test_browsingTheEditorialFeed_showsLoadedPhotosAndPagesOnScroll() {
        let app = launchWithStubs()
        let grid = app.scrollViews["photo-grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5), "The feed grid should appear on launch")

        let firstCell = app.images.matching(identifier: "photo-cell").firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "The first page should show its first cell")
        XCTAssertEqual(firstCell.label, "Fixture photo 1", "The first cell should be the first fixture Photo")

        let loaded = NSPredicate(format: "value == nil OR value == ''")
        expectation(for: loaded, evaluatedWith: firstCell)
        waitForExpectations(timeout: 5)

        let firstPhotoOfPage2 = app.images["Fixture photo 31"]
        scrollUntil(firstPhotoOfPage2, in: grid)
        XCTAssertTrue(firstPhotoOfPage2.waitForExistence(timeout: 5), "Scrolling to the end should load the next page")
    }

    @MainActor
    func test_searching_showsResultsAndClearingReturnsToTheFeedWhereItWas() {
        let app = launchWithStubs()
        let grid = app.scrollViews["photo-grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5), "The feed grid should appear on launch")

        let firstPhotoOfPage2 = app.images["Fixture photo 31"]
        scrollUntil(firstPhotoOfPage2, in: grid)
        XCTAssertTrue(firstPhotoOfPage2.waitForExistence(timeout: 5), "Scrolling to the end should load the next page")

        submitSearch("cats", in: app)
        XCTAssertTrue(
            app.images["Cat fixture photo 1"].waitForExistence(timeout: 5),
            "Submitting a Query should show its Search results")
        XCTAssertFalse(app.images["Fixture photo 1"].exists, "The feed should be hidden while Search results show")

        let field = app.searchFields.firstMatch
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "cats".count))

        XCTAssertTrue(
            app.images["Fixture photo 31"].waitForExistence(timeout: 5),
            "Clearing the Query should return to the feed at its scroll position")
        XCTAssertFalse(app.images["Cat fixture photo 1"].exists, "Clearing the Query should remove its Search results")
    }

    @MainActor
    private func scrollUntil(_ element: XCUIElement, in grid: XCUIElement) {
        for _ in 0..<20 where !element.exists {
            grid.swipeUp(velocity: .fast)
        }
    }

    @MainActor
    private func submitSearch(_ query: String, in app: XCUIApplication) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "The search field should be visible")
        field.tap()
        field.typeText(query + "\n")
    }

    @MainActor
    private func launchWithStubs() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-useStubs"]
        app.launch()
        return app
    }
}
