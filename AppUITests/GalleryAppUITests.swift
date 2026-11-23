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
        XCTAssertLessThanOrEqual(
            firstCell.frame.width, grid.frame.width / 2,
            "The cell's accessibility frame should be the cell, not its overflowing image")

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
    func test_openingAPhoto_showsItFullScreenWithItsCreditAndClosesBackToTheGrid() {
        let app = launchWithStubs()
        let firstCell = app.images["Fixture photo 1"]
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "The first feed cell should appear")

        firstCell.tap()

        let fullScreenPhoto = app.images.matching(identifier: "full-screen-photo").firstMatch
        XCTAssertTrue(fullScreenPhoto.waitForExistence(timeout: 5), "Tapping a cell should open its Photo full screen")
        XCTAssertEqual(
            fullScreenPhoto.label, "Fixture photo 1", "The full-screen Photo should be labelled with its Caption")

        let credit = app.descendants(matching: .any).matching(identifier: "photo-credit").firstMatch
        XCTAssertTrue(credit.waitForExistence(timeout: 5), "The full-screen view should show the Photographer credit")
        XCTAssertTrue(credit.label.contains("Fixture Photographer 2"), "The credit should name the Photographer")

        app.buttons.matching(identifier: "full-screen-close").firstMatch.tap()

        XCTAssertTrue(fullScreenPhoto.waitForNonExistence(timeout: 5), "Close should leave the Photo full screen")
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "Closing should return to the grid")
        XCTAssertTrue(firstCell.isHittable, "The grid cell should be back on screen after closing")
    }

    @MainActor
    func test_launchingOffline_showsTheSavedFeedWithABannerAndKeepsItOnFailedRefresh() {
        let online = launchWithStubs(extraArguments: ["-resetOfflineFeed"])
        XCTAssertTrue(
            online.images["Fixture photo 1"].waitForExistence(timeout: 5),
            "The online launch should load and save the feed")
        online.terminate()

        let offline = launchWithStubs(extraArguments: ["-stubOffline"])
        let firstCell = offline.images["Fixture photo 1"]
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "The saved feed should show when launching offline")
        XCTAssertTrue(
            offline.descendants(matching: .any).matching(identifier: "offline-banner").firstMatch
                .waitForExistence(timeout: 5),
            "The Offline banner should label the saved feed")

        let banner = offline.descendants(matching: .any).matching(identifier: "offline-banner").firstMatch
        let pullStart = banner.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        pullStart.press(forDuration: 0.05, thenDragTo: pullStart.withOffset(CGVector(dx: 0, dy: 400)))

        XCTAssertTrue(firstCell.waitForExistence(timeout: 5), "A failed refresh should keep the saved Photos")
        XCTAssertTrue(banner.exists, "A failed refresh should keep the Offline banner")
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
    private func launchWithStubs(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-useStubs"] + extraArguments
        app.launch()
        return app
    }
}
