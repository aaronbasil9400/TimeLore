import XCTest

final class BreadcrumbUITests: XCTestCase {
    func testCanOpenTheNewReminderForm() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["New reminder"].tap()

        XCTAssertTrue(app.navigationBars["New reminder"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["Reminder title"].exists)
    }
}
