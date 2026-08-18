import Foundation
import Testing
@testable import Breadcrumb

struct ReminderDraftTests {
    private let referenceDate = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func trimsSavedValues() {
        let draft = ReminderDraft(title: "  Call Maya  ", reason: "  Confirm the supplier quote.\n")

        #expect(draft.normalizedTitle == "Call Maya")
        #expect(draft.normalizedReason == "Confirm the supplier quote.")
    }

    @Test func rejectsAnEmptyTitle() {
        let draft = ReminderDraft(title: " \n ")

        #expect(draft.validationError(now: referenceDate) == "Add a reminder title.")
    }

    @Test func rejectsAPastDueDate() {
        let draft = ReminderDraft(title: "Renew passport", dueAt: referenceDate.addingTimeInterval(-1))

        #expect(draft.validationError(now: referenceDate) == "Choose a future date and time.")
    }

    @Test func acceptsAValidFutureReminder() {
        let draft = ReminderDraft(title: "Renew passport", dueAt: referenceDate.addingTimeInterval(60))

        #expect(draft.validationError(now: referenceDate) == nil)
    }
}
