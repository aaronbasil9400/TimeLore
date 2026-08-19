import XCTest

final class TimeLoreUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCanOpenTheNewReminderForm() {
        let app = makeApp()
        app.launch()

        app.buttons["New reminder"].tap()

        XCTAssertTrue(app.navigationBars["New reminder"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["Reminder title"].exists)
    }

    func testCanCreateATaggedReminderAndOpenItsDetail() {
        let app = makeApp()
        app.launch()

        app.buttons["New reminder"].tap()
        app.textFields["reminder.title"].tap()
        app.textFields["reminder.title"].typeText("Collect parcel")
        app.textFields["tag.newName"].tap()
        app.textFields["tag.newName"].typeText("Errands")
        app.buttons["Add"].tap()
        app.buttons["reminder.save"].tap()

        XCTAssertTrue(app.staticTexts["Collect parcel"].waitForExistence(timeout: 2))
        app.staticTexts["Collect parcel"].tap()
        XCTAssertTrue(app.navigationBars["Reminder"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Errands"].exists)
    }

    func testOpenSectionRemembersItsCollapsedState() {
        let app = makeApp()
        app.launch()

        let openSection = app.buttons["section.open"]
        let emptyMessage = app.staticTexts["No open reminders"]
        XCTAssertTrue(openSection.waitForExistence(timeout: 2))
        XCTAssertTrue(emptyMessage.exists)

        openSection.tap()
        XCTAssertFalse(emptyMessage.exists)

        app.terminate()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        XCTAssertFalse(app.staticTexts["No open reminders"].exists)
        app.buttons["section.open"].tap()
        XCTAssertTrue(app.staticTexts["No open reminders"].waitForExistence(timeout: 2))
    }

    func testCanEditTransitionArchiveRestoreAndDeleteAReminder() {
        let app = makeApp()
        app.launch()
        createReminder(named: "Lifecycle reminder", in: app)

        app.staticTexts["Lifecycle reminder"].tap()
        app.buttons["Edit"].tap()
        app.textFields["reminder.reason"].tap()
        app.textFields["reminder.reason"].typeText("Keep the original context")
        app.buttons["reminder.save"].tap()
        XCTAssertTrue(app.staticTexts["Keep the original context"].waitForExistence(timeout: 2))

        app.buttons["Mark as completed"].tap()
        XCTAssertTrue(app.buttons["Reopen reminder"].exists)
        app.buttons["Reopen reminder"].tap()
        XCTAssertTrue(app.buttons["Mark as completed"].exists)

        app.buttons["Archive reminder"].tap()
        XCTAssertTrue(app.buttons["Restore reminder"].exists)
        app.buttons["Restore reminder"].tap()
        XCTAssertTrue(app.buttons["Archive reminder"].exists)

        app.buttons["Delete reminder"].tap()
        app.alerts["Delete this reminder?"].buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Reminder"].exists)

        app.buttons["Delete reminder"].tap()
        app.alerts["Delete this reminder?"].buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["No open reminders"].waitForExistence(timeout: 2))
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-ui-testing-state"]
        return app
    }

    private func createReminder(named title: String, in app: XCUIApplication) {
        app.buttons["New reminder"].tap()
        app.textFields["reminder.title"].tap()
        app.textFields["reminder.title"].typeText(title)
        app.buttons["reminder.save"].tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 2))
    }
}
