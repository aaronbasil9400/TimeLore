import XCTest

final class TimeLoreUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testShowsSeededTagsAndCanOpenTheNewReminderForm() {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.images["brand.logo.expanded"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Remember what, and why."].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Work filter"].exists)
        XCTAssertTrue(app.buttons["Important filter"].exists)
        XCTAssertEqual(app.buttons["All filter"].value as? String, "Selected")

        app.buttons["Important filter"].tap()
        XCTAssertEqual(app.buttons["Important filter"].value as? String, "Selected")
        XCTAssertEqual(app.buttons["All filter"].value as? String, "Not selected")

        app.buttons["New reminder"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["New reminder"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["Reminder title"].exists)
        XCTAssertTrue(app.buttons["Tag Work"].exists)
    }

    func testNewReminderFormUsesTheNativeRepeatAndAttachmentControls() {
        let app = makeApp()
        app.launch()

        app.buttons["New reminder"].firstMatch.tap()
        let dueDateToggle = app.switches["Set a due date"]
        dueDateToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        XCTAssertTrue(app.buttons["reminder.repeat"].waitForExistence(timeout: 2))
        app.swipeUp()
        XCTAssertTrue(app.buttons["attachment.addFile"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["attachment.addContact"].exists)
    }

    func testSortMenuCanSelectPriorityOrder() {
        let app = makeApp()
        app.launch()

        let moreButton = app.buttons["reminder.moreActions"]
        moreButton.tap()
        app.buttons["Priority"].tap()

        XCTAssertEqual(moreButton.value as? String, "Sorted by Priority")
    }

    func testCanCreateAndRestyleATagFromTheHomeOverflow() {
        let app = makeApp()
        app.launch()

        openTagManagement(in: app)
        XCTAssertTrue(app.navigationBars["Manage Tags"].waitForExistence(timeout: 2))
        app.buttons["tag.manage.add"].tap()

        let nameField = app.textFields["tag.editor.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Travel")
        app.buttons["tag.color.red"].tap()
        scrollUntilHittable(app.buttons["tag.icon.airplane"], in: app)
        app.buttons["tag.icon.airplane"].tap()
        app.buttons["tag.editor.save"].tap()

        let travelRow = app.buttons["Edit Travel tag"]
        scrollUntilHittable(travelRow, in: app)
        XCTAssertEqual(travelRow.value as? String, "Used by 0 reminders")
        travelRow.tap()

        replaceText(in: app.textFields["tag.editor.name"], with: "Trips")
        app.buttons["tag.color.purple"].tap()
        scrollUntilHittable(app.buttons["tag.icon.house"], in: app)
        app.buttons["tag.icon.house"].tap()
        app.buttons["tag.editor.save"].tap()

        let tripsRow = app.buttons["Edit Trips tag"]
        scrollUntilHittable(tripsRow, in: app)
        XCTAssertTrue(tripsRow.exists)
        addScreenshot(named: "Manage Tags", of: app)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Trips filter"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Travel filter"].exists)
    }

    func testDeletingAnInUseTagRequiresConfirmationAndKeepsTheReminder() {
        let app = makeApp()
        app.launch()

        app.buttons["New reminder"].firstMatch.tap()
        app.textFields["reminder.title"].tap()
        app.textFields["reminder.title"].typeText("Tagged reminder")
        app.buttons["Tag Work"].tap()
        app.buttons["reminder.save"].tap()
        XCTAssertTrue(app.staticTexts["Tagged reminder"].waitForExistence(timeout: 2))

        openTagManagement(in: app)
        let workRow = app.buttons["Edit Work tag"]
        XCTAssertTrue(workRow.waitForExistence(timeout: 2))
        XCTAssertEqual(workRow.value as? String, "Used by 1 reminder")
        workRow.swipeLeft()
        app.buttons["Delete"].tap()

        let alert = app.alerts["Delete “Work”?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        XCTAssertTrue(alert.staticTexts["This removes the tag from 1 reminder. The reminders will not be deleted."].exists)
        alert.buttons["Delete Tag"].tap()

        XCTAssertFalse(app.buttons["Edit Work tag"].exists)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Tagged reminder"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Work filter"].exists)
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

    func testBrandLogoCompactsWhenTheReminderListScrolls() {
        let app = makeApp()
        app.launch()

        for index in 1...10 {
            createReminder(named: "Scrollable reminder \(index)", in: app)
        }

        XCTAssertTrue(app.images["brand.logo.expanded"].exists)
        app.swipeUp()
        XCTAssertTrue(app.images["brand.logo.compact"].waitForExistence(timeout: 2))
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

        let deleteAlert = openDeleteAlert(in: app)
        deleteAlert.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Reminder"].exists)

        let confirmedDeleteAlert = openDeleteAlert(in: app)
        confirmedDeleteAlert.buttons["Delete"].tap()
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

    private func openTagManagement(in app: XCUIApplication) {
        app.buttons["reminder.moreActions"].tap()
        let manageTags = app.buttons["Manage Tags"]
        XCTAssertTrue(manageTags.waitForExistence(timeout: 2))
        manageTags.tap()
    }

    private func scrollUntilHittable(
        _ element: XCUIElement,
        in app: XCUIApplication
    ) {
        for _ in 0..<5 where !element.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    private func replaceText(in field: XCUIElement, with replacement: String) {
        field.tap()
        let currentValue = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count))
        field.typeText(replacement)
    }

    private func addScreenshot(named name: String, of app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func openDeleteAlert(in app: XCUIApplication) -> XCUIElement {
        app.buttons["detail.moreActions"].tap()
        let deleteMenuButton = app.buttons["Delete"].firstMatch
        XCTAssertTrue(deleteMenuButton.waitForExistence(timeout: 2))
        deleteMenuButton.tap()

        let alert = app.alerts["Delete this reminder?"]
        if !alert.waitForExistence(timeout: 1), deleteMenuButton.exists {
            deleteMenuButton.tap()
        }
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        return alert
    }
}
