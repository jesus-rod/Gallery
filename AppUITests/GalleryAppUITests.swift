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
    private func launchWithStubs() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-useStubs"]
        app.launch()
        return app
    }
}
