import Foundation
import Testing
@testable import TimeLore

struct ReminderImportantTests {
    private let createdAt = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func importantSurvivesEveryLifecycleTransition() {
        let reminder = Reminder(draft: ReminderDraft(title: "Book hotel"), now: createdAt)
        let flaggedAt = createdAt.addingTimeInterval(60)

        reminder.setImportant(true, at: flaggedAt)
        reminder.complete(at: createdAt.addingTimeInterval(120))
        reminder.archive(at: createdAt.addingTimeInterval(180))
        reminder.restore(at: createdAt.addingTimeInterval(240))
        reminder.reopen(at: createdAt.addingTimeInterval(300))

        #expect(reminder.isImportant)
        #expect(reminder.status == .open)
        #expect(reminder.archivedAt == nil)
        #expect(reminder.completedAt == nil)
    }

    @Test func aNewReminderCopiesItsImportantDraftValue() {
        let reminder = Reminder(draft: ReminderDraft(title: "Book hotel", isImportant: true), now: createdAt)

        #expect(reminder.isImportant)
    }

    @Test func priorityIsIndependentAndSurvivesLifecycleTransitions() {
        let reminder = Reminder(
            draft: ReminderDraft(title: "Book hotel", isImportant: true, priority: .level2),
            now: createdAt
        )
        let updatedAt = createdAt.addingTimeInterval(360)

        reminder.complete(at: createdAt.addingTimeInterval(120))
        reminder.archive(at: createdAt.addingTimeInterval(180))
        reminder.restore(at: createdAt.addingTimeInterval(240))
        reminder.reopen(at: createdAt.addingTimeInterval(300))
        reminder.setPriority(.level3, at: updatedAt)

        #expect(reminder.priority == .level3)
        #expect(reminder.isImportant)
        #expect(reminder.status == .open)
        #expect(reminder.archivedAt == nil)
        #expect(reminder.updatedAt == updatedAt)
    }

    @Test func changingImportantOnlyChangesUpdatedTime() {
        let reminder = Reminder(draft: ReminderDraft(title: "Send report"), now: createdAt)
        let completedAt = createdAt.addingTimeInterval(60)
        let flaggedAt = createdAt.addingTimeInterval(120)
        reminder.complete(at: completedAt)

        reminder.setImportant(true, at: flaggedAt)

        #expect(reminder.completedAt == completedAt)
        #expect(reminder.archivedAt == nil)
        #expect(reminder.updatedAt == flaggedAt)
    }

    @Test func editingPersistsAnExplicitImportantValue() {
        let reminder = Reminder(draft: ReminderDraft(title: "Send report"), now: createdAt)
        reminder.update(
            from: ReminderDraft(title: "Send report", isImportant: true),
            tags: [],
            now: createdAt.addingTimeInterval(60)
        )

        #expect(reminder.isImportant)
    }
}
