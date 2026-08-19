import SwiftData

@MainActor
enum DefaultReminderTagSeeder {
    static let defaultNames = ["Work", "Personal", "Projects", "Grocery", "Health", "Errands"]

    static func seed(in modelContext: ModelContext) throws {
        let existingTags = try modelContext.fetch(FetchDescriptor<ReminderTag>())
        let existingNames = Set(existingTags.map(\.normalizedName))

        for name in defaultNames where !existingNames.contains(ReminderTag.normalizedName(from: name)) {
            modelContext.insert(ReminderTag(name: name))
        }
    }
}
