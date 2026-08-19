import XCTest

final class TimeLoreUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testShowsSeededTagsAndCanOpenTheNewReminderForm() {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.staticTexts["Remember what, and why."].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Work filter"].exists)
        XCTAssertTrue(app.buttons["Important filter"].exists)

        app.buttons["New reminder"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["New reminder"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["Reminder title"].exists)
        XCTAssertTrue(app.buttons["Tag Work"].exists)
    }

    func testSortMenuCanSelectPriorityOrder() {
        let app = makeApp()
        app.launch()

        let sortButton = app.buttons["reminder.sort"]
        sortButton.tap()
        app.buttons["Priority"].tap()

        XCTAssertEqual(sortButton.value as? String, "Priority")
    }

    func testCanCreateAnImportantTaggedReminderSearchAndOpenDetail() {
        let app = makeApp()
        app.launch()

        app.buttons["New reminder"].firstMatch.tap()
        let importantToggle = app.switches["reminder.important"]
        importantToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(importantToggle.value as? String, "1")
        app.textFields["reminder.title"].tap()
        app.textFields["reminder.title"].typeText("Collect parcel")
        app.textFields["reminder.reason"].tap()
        app.textFields["reminder.reason"].typeText("Pickup before Friday")
        app.buttons["Tag Errands"].tap()
        app.buttons["reminder.save"].tap()

        XCTAssertTrue(app.staticTexts["Collect parcel"].waitForExistence(timeout: 2))
        app.buttons["Important filter"].tap()
        XCTAssertTrue(app.staticTexts["Collect parcel"].exists)

        app.buttons["All filter"].tap()
        app.searchFields["Search reminders"].tap()
        app.searchFields["Search reminders"].typeText("friday")
        XCTAssertTrue(app.staticTexts["Collect parcel"].waitForExistence(timeout: 2))
        app.staticTexts["Collect parcel"].tap()
        XCTAssertTrue(app.navigationBars["Reminder"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["NOTES"].exists)
        XCTAssertTrue(app.switches["detail.important"].value as? String == "1")
        XCTAssertTrue(app.staticTexts["Errands"].exists)
    }

    func testOpenSectionCanCollapseAndExpand() {
        let app = makeApp()
        app.launch()
        createReminder(named: "Section reminder", in: app)

        let openSection = app.buttons["section.open"].firstMatch
        XCTAssertTrue(openSection.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Section reminder"].exists)
        openSection.tap()
        XCTAssertFalse(app.staticTexts["Section reminder"].exists)
        openSection.tap()
        XCTAssertTrue(app.staticTexts["Section reminder"].waitForExistence(timeout: 2))
    }

    func testDirectionalSwipesProgressAndOrganizeAReminder() {
        let app = makeApp()
        app.launch()
        createReminder(named: "Swipe reminder", in: app)

        app.staticTexts["Swipe reminder"].swipeLeft()
        app.buttons["Flag"].tap()
        app.buttons["Important filter"].tap()
        XCTAssertTrue(app.staticTexts["Swipe reminder"].exists)

        app.buttons["All filter"].tap()
        app.staticTexts["Swipe reminder"].swipeRight()
        app.buttons["section.completed"].tap()
        XCTAssertTrue(app.staticTexts["Swipe reminder"].waitForExistence(timeout: 2))
    }

    func testTappingTheCompletionCircleCompletesAReminderWithoutOpeningDetail() {
        let app = makeApp()
        app.launch()
        createReminder(named: "Tap completion", in: app)

        app.buttons["Mark Tap completion as completed"].tap()

        XCTAssertFalse(app.navigationBars["Reminder"].exists)
        app.buttons["section.completed"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Tap completion"].waitForExistence(timeout: 2))
    }

    func testCanEditTransitionArchiveRestoreAndDeleteAReminder() {
        let app = makeApp()
        app.launch()
        createReminder(named: "Lifecycle reminder", in: app)

        app.staticTexts["Lifecycle reminder"].tap()
        app.buttons["detail.moreActions"].tap()
        app.buttons["Edit"].tap()
        app.textFields["reminder.reason"].tap()
        app.textFields["reminder.reason"].typeText("Keep the original context")
        app.buttons["reminder.save"].tap()
        XCTAssertTrue(app.staticTexts["Keep the original context"].waitForExistence(timeout: 2))

        app.buttons["detail.statusAction"].tap()
        XCTAssertTrue(app.buttons["detail.statusAction"].label.contains("Reopen"))
        app.buttons["detail.statusAction"].tap()

        app.buttons["detail.moreActions"].tap()
        app.buttons["Archive"].tap()
        app.buttons["detail.moreActions"].tap()
        app.buttons["Restore"].tap()

        app.buttons["detail.moreActions"].tap()
        app.buttons["Delete"].tap()
        app.alerts["Delete this reminder?"].buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Reminder"].exists)

        app.buttons["detail.moreActions"].tap()
        app.buttons["Delete"].tap()
        app.alerts["Delete this reminder?"].buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Remember what, and why."].waitForExistence(timeout: 2))
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-ui-testing-state"]
        return app
    }

    private func createReminder(named title: String, in app: XCUIApplication) {
        app.buttons["New reminder"].firstMatch.tap()
        app.textFields["reminder.title"].tap()
        app.textFields["reminder.title"].typeText(title)
        app.buttons["reminder.save"].tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 2))
    }
}
