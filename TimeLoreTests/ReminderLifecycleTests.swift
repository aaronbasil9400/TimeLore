import Foundation
import Testing
@testable import TimeLore

struct ReminderLifecycleTests {
    private let createdAt = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func editingPreservesIdentityAndCreationTime() {
        let reminder = Reminder(draft: ReminderDraft(title: "Original"), now: createdAt)
        let originalID = reminder.id
        let updatedAt = createdAt.addingTimeInterval(60)
        let tag = ReminderTag(name: "Work")

        reminder.update(
            from: ReminderDraft(title: "  Updated  ", reason: "  Useful context  "),
            tags: [tag],
            now: updatedAt
        )

        #expect(reminder.id == originalID)
        #expect(reminder.createdAt == createdAt)
        #expect(reminder.updatedAt == updatedAt)
        #expect(reminder.title == "Updated")
        #expect(reminder.reason == "Useful context")
        #expect(reminder.tags.map(\.name) == ["Work"])
    }

    @Test func completionAndReopeningRecordTransitions() {
        let reminder = Reminder(draft: ReminderDraft(title: "Call Maya"), now: createdAt)
        let completedAt = createdAt.addingTimeInterval(60)
        let reopenedAt = createdAt.addingTimeInterval(120)

        reminder.complete(at: completedAt)

        #expect(reminder.status == .completed)
        #expect(reminder.completedAt == completedAt)
        #expect(reminder.updatedAt == completedAt)

        reminder.reopen(at: reopenedAt)

        #expect(reminder.status == .open)
        #expect(reminder.completedAt == nil)
        #expect(reminder.updatedAt == reopenedAt)
    }

    @Test func repeatedCompletionDoesNotRewriteHistory() {
        let reminder = Reminder(draft: ReminderDraft(title: "Call Maya"), now: createdAt)
        let firstCompletion = createdAt.addingTimeInterval(60)

        reminder.complete(at: firstCompletion)
        reminder.complete(at: createdAt.addingTimeInterval(120))

        #expect(reminder.completedAt == firstCompletion)
        #expect(reminder.updatedAt == firstCompletion)
    }

    @Test func archivingDoesNotChangeCompletionStatus() {
        let reminder = Reminder(draft: ReminderDraft(title: "File receipt"), now: createdAt)
        let completedAt = createdAt.addingTimeInterval(60)
        let archivedAt = createdAt.addingTimeInterval(120)

        reminder.complete(at: completedAt)
        reminder.archive(at: archivedAt)

        #expect(reminder.status == .completed)
        #expect(reminder.completedAt == completedAt)
        #expect(reminder.archivedAt == archivedAt)

        reminder.restore(at: createdAt.addingTimeInterval(180))

        #expect(reminder.status == .completed)
        #expect(reminder.archivedAt == nil)
    }
}
