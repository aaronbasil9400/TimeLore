import SwiftData
import Testing
@testable import Breadcrumb

@MainActor
struct ReminderPersistenceTests {
    @Test func reminderAndMultipleTagsPersistTogether() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let work = ReminderTag(name: "Work")
        let errands = ReminderTag(name: "Errands")
        let reminder = Reminder(draft: ReminderDraft(title: "Collect parcel"))
        reminder.tags = [work, errands]

        context.insert(reminder)
        try context.save()

        let fetchedReminders = try context.fetch(FetchDescriptor<Reminder>())
        let fetchedTags = try context.fetch(FetchDescriptor<ReminderTag>())

        #expect(fetchedReminders.count == 1)
        #expect(Set(fetchedReminders[0].tags.map(\.normalizedName)) == Set(["work", "errands"]))
        #expect(fetchedTags.count == 2)
    }

    @Test func deletingATagDoesNotDeleteItsReminder() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let tag = ReminderTag(name: "Work")
        let reminder = Reminder(draft: ReminderDraft(title: "Send invoice"))
        reminder.tags = [tag]

        context.insert(reminder)
        try context.save()
        context.delete(tag)
        try context.save()

        let fetchedReminders = try context.fetch(FetchDescriptor<Reminder>())

        #expect(fetchedReminders.count == 1)
        #expect(fetchedReminders[0].tags.isEmpty)
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Reminder.self,
            ReminderTag.self,
            configurations: configuration
        )
    }
}
