import SwiftData
import Testing
@testable import TimeLore

@MainActor
struct DefaultReminderTagSeederTests {
    @Test func seedingAddsTheSixDefaultsOnlyOnce() throws {
        let container = try makeContainer()
        let context = container.mainContext

        try DefaultReminderTagSeeder.seed(in: context)
        try DefaultReminderTagSeeder.seed(in: context)
        try context.save()

        let tags = try context.fetch(FetchDescriptor<ReminderTag>())
        #expect(Set(tags.map(\.normalizedName)) == Set(["work", "personal", "projects", "grocery", "health", "errands"]))
        #expect(tags.count == 6)
    }

    @Test func seedingRecognizesAnExistingCaseInsensitiveDefault() throws {
        let container = try makeContainer()
        let context = container.mainContext
        context.insert(ReminderTag(name: "WORK"))

        try DefaultReminderTagSeeder.seed(in: context)
        try context.save()

        let tags = try context.fetch(FetchDescriptor<ReminderTag>())
        #expect(tags.filter { $0.normalizedName == "work" }.count == 1)
        #expect(tags.count == 6)
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
}
