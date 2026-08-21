import Foundation
import SwiftData

@MainActor
enum DefaultReminderTagSeeder {
    struct Definition {
        let key: String
        let name: String
        let colorToken: ReminderTagColorToken
        let symbolName: String
    }

    static let definitions = [
        Definition(key: "work", name: "Work", colorToken: .blue, symbolName: "briefcase"),
        Definition(key: "personal", name: "Personal", colorToken: .purple, symbolName: "person"),
        Definition(key: "projects", name: "Projects", colorToken: .indigo, symbolName: "folder"),
        Definition(key: "grocery", name: "Grocery", colorToken: .green, symbolName: "cart"),
        Definition(key: "health", name: "Health", colorToken: .pink, symbolName: "heart"),
        Definition(key: "errands", name: "Errands", colorToken: .teal, symbolName: "checklist")
    ]
    static let defaultNames = definitions.map(\.name)
    private static let suppressedDefaultsKey = "tags.suppressedDefaultSeedKeys"

    static func seed(in modelContext: ModelContext, defaults: UserDefaults = .standard) throws {
        let existingTags = try modelContext.fetch(FetchDescriptor<ReminderTag>())
        let suppressedKeys = suppressedDefaultKeys(in: defaults)

        for definition in definitions {
            if existingTags.contains(where: { $0.defaultSeedKey == definition.key }) {
                continue
            }
            if suppressedKeys.contains(definition.key) {
                continue
            }
            if let existing = existingTags.first(where: {
                $0.normalizedName == ReminderTag.normalizedName(from: definition.name)
            }) {
                configure(existing, as: definition)
                continue
            }
            modelContext.insert(ReminderTag(
                name: definition.name,
                colorToken: definition.colorToken,
                symbolName: definition.symbolName,
                defaultSeedKey: definition.key
            ))
        }
    }

    static func rank(for tag: ReminderTag) -> Int {
        guard let key = tag.defaultSeedKey else { return .max }
        return definitions.firstIndex(where: { $0.key == key }) ?? .max
    }

    static func prepareNewTag(
        _ tag: ReminderTag,
        useDefaultAppearance: Bool = false,
        in modelContext: ModelContext? = nil,
        defaults: UserDefaults = .standard
    ) {
        guard let definition = definitions.first(where: {
            ReminderTag.normalizedName(from: $0.name) == tag.normalizedName
        }) else { return }
        if let modelContext,
           let tags = try? modelContext.fetch(FetchDescriptor<ReminderTag>()),
           tags.contains(where: { $0.defaultSeedKey == definition.key }) {
            return
        }

        tag.defaultSeedKey = definition.key
        if useDefaultAppearance {
            tag.setAppearance(colorToken: definition.colorToken, symbolName: definition.symbolName)
        }
        var keys = suppressedDefaultKeys(in: defaults)
        keys.remove(definition.key)
        defaults.set(Array(keys).sorted(), forKey: suppressedDefaultsKey)
    }

    static func suppressDefault(for tag: ReminderTag, defaults: UserDefaults = .standard) {
        guard let key = tag.defaultSeedKey else { return }
        var keys = suppressedDefaultKeys(in: defaults)
        keys.insert(key)
        defaults.set(Array(keys).sorted(), forKey: suppressedDefaultsKey)
    }

    static func resetSuppressedDefaults(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: suppressedDefaultsKey)
    }

    private static func configure(_ tag: ReminderTag, as definition: Definition) {
        tag.defaultSeedKey = definition.key
        tag.setAppearance(colorToken: definition.colorToken, symbolName: definition.symbolName)
    }

    private static func suppressedDefaultKeys(in defaults: UserDefaults) -> Set<String> {
        Set(defaults.stringArray(forKey: suppressedDefaultsKey) ?? [])
    }
}
