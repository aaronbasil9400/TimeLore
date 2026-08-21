import Foundation
import SwiftData
import Testing
import UniformTypeIdentifiers
@testable import TimeLore

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

    @Test func tagManagerRenamesAppearanceAndRecurringTemplateTogether() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let tag = ReminderTag(name: "Work", colorToken: .blue, symbolName: "briefcase")
        let reminder = Reminder(draft: ReminderDraft(title: "Send update"))
        reminder.tags = [tag]
        let dueAt = Date.now.addingTimeInterval(86_400)
        let series = ReminderSeries(
            draft: ReminderDraft(
                title: "Weekly update",
                dueAt: dueAt,
                repeatRule: .from(dueAt: dueAt, frequency: .weekly)
            ),
            tagNames: [tag.normalizedName]
        )
        context.insert(reminder)
        context.insert(series)
        try context.save()

        try ReminderTagManager().update(
            tag,
            name: "Clients",
            colorToken: .orange,
            symbolName: "person.2",
            in: context
        )

        #expect(reminder.tags.first?.id == tag.id)
        #expect(tag.name == "Clients")
        #expect(tag.normalizedName == "clients")
        #expect(tag.colorToken == .orange)
        #expect(tag.resolvedSymbolName == "person.2")
        #expect(series.templateTagNames == ["clients"])
    }

    @Test func tagManagerDeletionDetachesReminderAndRecurringTemplate() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let tag = ReminderTag(name: "Projects")
        let reminder = Reminder(draft: ReminderDraft(title: "Keep this reminder"))
        reminder.tags = [tag]
        let dueAt = Date.now.addingTimeInterval(86_400)
        let series = ReminderSeries(
            draft: ReminderDraft(
                title: "Recurring project",
                dueAt: dueAt,
                repeatRule: .from(dueAt: dueAt, frequency: .weekly)
            ),
            tagNames: [tag.normalizedName]
        )
        context.insert(reminder)
        context.insert(series)
        try context.save()

        try ReminderTagManager().delete(tag, in: context)

        let reminders = try context.fetch(FetchDescriptor<Reminder>())
        #expect(reminders.map(\.title) == ["Keep this reminder"])
        #expect(reminders[0].tags.isEmpty)
        #expect(series.templateTagNames.isEmpty)
    }

    @Test func tagManagerRejectsCaseInsensitiveDuplicates() throws {
        let container = try makeContainer()
        let context = container.mainContext
        context.insert(ReminderTag(name: "Work"))
        try context.save()

        #expect(throws: ReminderTagManagementError.duplicateName) {
            try ReminderTagManager().create(
                name: " work ",
                colorToken: .green,
                symbolName: "tag",
                in: context
            )
        }
    }

    @Test func attachmentRelationshipSurvivesAContextRefetch() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let store = ReminderAttachmentStore(rootURL: rootURL)
        let draft = try store.stage(
            data: Data("local context".utf8),
            kind: .file,
            displayName: "context.txt",
            contentTypeIdentifier: UTType.plainText.identifier,
            existingCount: 0,
            existingByteCount: 0
        )
        let attachment = try #require(store.commit([draft]).first)
        let reminder = Reminder(draft: ReminderDraft(title: "Keep the context"))

        context.insert(reminder)
        context.insert(attachment)
        attachment.reminder = reminder
        try context.save()

        let reloadedContext = ModelContext(container)
        let reloadedReminder = try #require(reloadedContext.fetch(FetchDescriptor<Reminder>()).first)
        let reloadedAttachment = try #require(reloadedReminder.attachments.first)

        #expect(reloadedAttachment.displayName == "context.txt")
        #expect(store.payloadURL(for: reloadedAttachment)?.pathExtension == "txt")
    }

    @Test func importedFileAttachmentsPersistForNormalAndRecurringReminders() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let sourceURL = rootURL.appendingPathComponent("source/agenda.txt")
        try FileManager.default.createDirectory(at: sourceURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("agenda context".utf8).write(to: sourceURL)

        let store = ReminderAttachmentStore(rootURL: rootURL.appendingPathComponent("storage", isDirectory: true))
        let normalFile = try store.stage(
            fileAt: sourceURL,
            displayName: "agenda.txt",
            contentTypeIdentifier: UTType.plainText.identifier,
            existingCount: 0,
            existingByteCount: 0
        )
        let recurringFile = try store.stage(
            fileAt: sourceURL,
            displayName: "agenda.txt",
            contentTypeIdentifier: UTType.plainText.identifier,
            existingCount: 0,
            existingByteCount: 0
        )
        try FileManager.default.removeItem(at: sourceURL)

        let normalReminder = Reminder(draft: ReminderDraft(title: "Read agenda"))
        context.insert(normalReminder)
        try store.commit([normalFile], attachingTo: normalReminder, in: context)

        let dueAt = Date.now.addingTimeInterval(86_400)
        let repeatRule = ReminderRepeatRule.from(dueAt: dueAt, frequency: .weekly)
        let recurringReminder = RecurringReminderService().createRecurringReminder(
            from: ReminderDraft(title: "Weekly agenda", dueAt: dueAt, repeatRule: repeatRule),
            tags: [],
            in: context
        )
        try store.commit([recurringFile], attachingTo: recurringReminder, in: context)
        try context.save()

        let reloadedContext = ModelContext(container)
        let reminders = try reloadedContext.fetch(FetchDescriptor<Reminder>())
        let reloadedNormal = try #require(reminders.first(where: { $0.id == normalReminder.id }))
        let reloadedRecurring = try #require(reminders.first(where: { $0.id == recurringReminder.id }))

        #expect(reloadedNormal.attachments.map(\.displayName) == ["agenda.txt"])
        #expect(reloadedRecurring.attachments.isEmpty)
        #expect(reloadedRecurring.recurrenceSeries?.attachments.map(\.displayName) == ["agenda.txt"])
        #expect(store.payloadURL(for: try #require(reloadedRecurring.recurrenceSeries?.attachments.first)) != nil)
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Reminder.self,
            ReminderTag.self,
            ReminderSeries.self,
            ReminderAttachment.self,
            configurations: configuration
        )
    }
}
