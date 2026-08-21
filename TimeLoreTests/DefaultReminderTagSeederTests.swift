import Foundation
import SwiftData
import Testing
@testable import TimeLore

@MainActor
struct DefaultReminderTagSeederTests {
    @Test func seedingAddsTheSixDefaultsOnlyOnce() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let defaults = try makeDefaults()
        defer { DefaultReminderTagSeeder.resetSuppressedDefaults(in: defaults) }

        try DefaultReminderTagSeeder.seed(in: context, defaults: defaults)
        try DefaultReminderTagSeeder.seed(in: context, defaults: defaults)
        try context.save()

        let tags = try context.fetch(FetchDescriptor<ReminderTag>())
        #expect(Set(tags.map(\.normalizedName)) == Set(["work", "personal", "projects", "grocery", "health", "errands"]))
        #expect(tags.count == 6)
    }

    @Test func seedingRecognizesAnExistingCaseInsensitiveDefault() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let defaults = try makeDefaults()
        defer { DefaultReminderTagSeeder.resetSuppressedDefaults(in: defaults) }
        context.insert(ReminderTag(name: "WORK"))

        try DefaultReminderTagSeeder.seed(in: context, defaults: defaults)
        try context.save()

        let tags = try context.fetch(FetchDescriptor<ReminderTag>())
        let work = try #require(tags.first { $0.normalizedName == "work" })
        #expect(tags.filter { $0.normalizedName == "work" }.count == 1)
        #expect(tags.count == 6)
        #expect(work.defaultSeedKey == "work")
        #expect(work.colorToken == .blue)
        #expect(work.resolvedSymbolName == "briefcase")
    }

    @Test func renamedDefaultIsNotRecreatedUnderItsOriginalName() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let defaults = try makeDefaults()
        defer { DefaultReminderTagSeeder.resetSuppressedDefaults(in: defaults) }
        try DefaultReminderTagSeeder.seed(in: context, defaults: defaults)
        try context.save()
        let work = try #require(try context.fetch(FetchDescriptor<ReminderTag>()).first { $0.defaultSeedKey == "work" })

        try ReminderTagManager(defaults: defaults).update(
            work,
            name: "Career",
            colorToken: .orange,
            symbolName: "star",
            in: context
        )
        try DefaultReminderTagSeeder.seed(in: context, defaults: defaults)
        try context.save()

        let tags = try context.fetch(FetchDescriptor<ReminderTag>())
        let career = try #require(tags.first { $0.normalizedName == "career" })
        #expect(tags.count == 6)
        #expect(tags.contains { $0.normalizedName == "work" } == false)
        #expect(career.defaultSeedKey == "work")
        #expect(career.colorToken == .orange)
        #expect(career.resolvedSymbolName == "star")
    }

    @Test func deletedDefaultStaysDeletedUntilItIsExplicitlyCreatedAgain() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let defaults = try makeDefaults()
        defer { DefaultReminderTagSeeder.resetSuppressedDefaults(in: defaults) }
        try DefaultReminderTagSeeder.seed(in: context, defaults: defaults)
        try context.save()
        let work = try #require(try context.fetch(FetchDescriptor<ReminderTag>()).first { $0.defaultSeedKey == "work" })

        try ReminderTagManager(defaults: defaults).delete(work, in: context)
        try DefaultReminderTagSeeder.seed(in: context, defaults: defaults)

        var tags = try context.fetch(FetchDescriptor<ReminderTag>())
        #expect(tags.count == 5)
        #expect(tags.contains { $0.normalizedName == "work" } == false)

        let recreated = try ReminderTagManager(defaults: defaults).create(
            name: "Work",
            colorToken: .red,
            symbolName: "star",
            in: context
        )
        try DefaultReminderTagSeeder.seed(in: context, defaults: defaults)
        tags = try context.fetch(FetchDescriptor<ReminderTag>())

        #expect(tags.count == 6)
        #expect(recreated.defaultSeedKey == "work")
        #expect(recreated.colorToken == .red)
        #expect(recreated.resolvedSymbolName == "star")
    }

    @Test func recreatingTheOriginalNameAfterRenameDoesNotDuplicateDefaultIdentity() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let defaults = try makeDefaults()
        defer { DefaultReminderTagSeeder.resetSuppressedDefaults(in: defaults) }
        try DefaultReminderTagSeeder.seed(in: context, defaults: defaults)
        try context.save()
        let work = try #require(try context.fetch(FetchDescriptor<ReminderTag>()).first { $0.defaultSeedKey == "work" })
        let manager = ReminderTagManager(defaults: defaults)

        try manager.update(
            work,
            name: "Career",
            colorToken: .orange,
            symbolName: "star",
            in: context
        )
        let newWork = try manager.create(
            name: "Work",
            colorToken: .red,
            symbolName: "briefcase",
            in: context
        )

        let tags = try context.fetch(FetchDescriptor<ReminderTag>())
        #expect(tags.count == 7)
        #expect(work.defaultSeedKey == "work")
        #expect(newWork.defaultSeedKey == nil)
        #expect(tags.filter { $0.defaultSeedKey == "work" }.count == 1)
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Reminder.self,
            ReminderTag.self,
            ReminderSeries.self,
            ReminderAttachment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "DefaultReminderTagSeederTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
