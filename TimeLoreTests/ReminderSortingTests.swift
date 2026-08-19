import Foundation
import Testing
@testable import TimeLore

struct ReminderSortingTests {
    @Test func putsDatedRemindersBeforeUndatedReminders() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let undated = Reminder(draft: ReminderDraft(title: "Undated"), now: now)
        let later = Reminder(draft: ReminderDraft(title: "Later", dueAt: now.addingTimeInterval(120)), now: now)
        let sooner = Reminder(draft: ReminderDraft(title: "Sooner", dueAt: now.addingTimeInterval(60)), now: now)

        let ordered = [undated, later, sooner].sorted(by: Reminder.openSortOrder)

        #expect(ordered.map(\.title) == ["Sooner", "Later", "Undated"])
    }

    @Test func prioritySortPlacesHigherLevelsFirstAndUsesDueDateAsATieBreaker() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let levelOne = Reminder(draft: ReminderDraft(title: "Level one", dueAt: now.addingTimeInterval(60), priority: .level1), now: now)
        let levelThree = Reminder(draft: ReminderDraft(title: "Level three", dueAt: now.addingTimeInterval(180), priority: .level3), now: now)
        let levelTwo = Reminder(draft: ReminderDraft(title: "Level two", dueAt: now.addingTimeInterval(120), priority: .level2), now: now)

        let ordered = [levelOne, levelThree, levelTwo].sorted(by: Reminder.prioritySortOrder)

        #expect(ordered.map(\.title) == ["Level three", "Level two", "Level one"])
    }
}
