import XCTest

final class GalleryAppUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func test_launch_showsTheFirstPageOfTheEditorialFeed() {
        let app = launchWithStubs()

        let firstCell = app.images.matching(identifier: "photo-cell").firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
        XCTAssertEqual(firstCell.label, "Fixture photo 1")
    }

    @MainActor
    func test_launch_loadsTheImagesOfTheFirstCells() {
        let app = launchWithStubs()

        let firstCell = app.images.matching(identifier: "photo-cell").firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5))

        let loaded = NSPredicate(format: "value == nil OR value == ''")
        expectation(for: loaded, evaluatedWith: firstCell)
        waitForExpectations(timeout: 5)
    }

    @MainActor
    func test_scrollingToTheEnd_loadsTheNextPage() {
        let app = launchWithStubs()
        let grid = app.scrollViews["photo-grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5))

        let firstPhotoOfPage2 = app.images["Fixture photo 31"]
        for _ in 0..<20 where !firstPhotoOfPage2.exists {
            grid.swipeUp(velocity: .fast)
        }

        XCTAssertTrue(firstPhotoOfPage2.waitForExistence(timeout: 5))
    }

    @MainActor
    func test_submittingAQuery_showsItsSearchResults() {
        let app = launchWithStubs()
        XCTAssertTrue(app.images["Fixture photo 1"].waitForExistence(timeout: 5))

        submitSearch("cats", in: app)

        XCTAssertTrue(app.images["Cat fixture photo 1"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.images["Fixture photo 1"].exists)
    }

    @MainActor
    func test_clearingTheQuery_returnsToTheFeedAtTheSameScrollPosition() {
        let app = launchWithStubs()
        let grid = app.scrollViews["photo-grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5))

        let firstPhotoOfPage2 = app.images["Fixture photo 31"]
        for _ in 0..<20 where !firstPhotoOfPage2.exists {
            grid.swipeUp(velocity: .fast)
        }
        XCTAssertTrue(firstPhotoOfPage2.waitForExistence(timeout: 5))

        submitSearch("cats", in: app)
        XCTAssertTrue(app.images["Cat fixture photo 1"].waitForExistence(timeout: 5))

        let field = app.searchFields.firstMatch
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "cats".count))

        XCTAssertTrue(app.images["Fixture photo 31"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.images["Cat fixture photo 1"].exists)
    }

    @MainActor
    func test_searchingWithNoResults_showsTheQueryInTheEmptyState() {
        let app = launchWithStubs()
        XCTAssertTrue(app.images["Fixture photo 1"].waitForExistence(timeout: 5))

        submitSearch("zzzz", in: app)

        XCTAssertTrue(app.staticTexts["No photos for “zzzz”"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func submitSearch(_ query: String, in app: XCUIApplication) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
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
