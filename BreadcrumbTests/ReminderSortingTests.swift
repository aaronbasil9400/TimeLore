import Foundation
import Testing
@testable import Breadcrumb

struct ReminderSortingTests {
    @Test func putsDatedRemindersBeforeUndatedReminders() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let undated = Reminder(draft: ReminderDraft(title: "Undated"), now: now)
        let later = Reminder(draft: ReminderDraft(title: "Later", dueAt: now.addingTimeInterval(120)), now: now)
        let sooner = Reminder(draft: ReminderDraft(title: "Sooner", dueAt: now.addingTimeInterval(60)), now: now)

        let ordered = [undated, later, sooner].sorted(by: Reminder.openSortOrder)

        #expect(ordered.map(\.title) == ["Sooner", "Later", "Undated"])
    }
}
