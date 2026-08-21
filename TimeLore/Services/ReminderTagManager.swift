import Foundation
import SwiftData

enum ReminderTagManagementError: LocalizedError, Equatable {
    case invalidName(String)
    case duplicateName

    var errorDescription: String? {
        switch self {
        case let .invalidName(message):
            message
        case .duplicateName:
            "A tag with this name already exists."
        }
    }
}

@MainActor
struct ReminderTagManager {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    @discardableResult
    func create(
        name: String,
        colorToken: ReminderTagColorToken,
        symbolName: String,
        in modelContext: ModelContext
    ) throws -> ReminderTag {
        let displayName = try validatedDisplayName(name, excluding: nil, in: modelContext)
        let tag = ReminderTag(name: displayName, colorToken: colorToken, symbolName: symbolName)
        DefaultReminderTagSeeder.prepareNewTag(tag, in: modelContext, defaults: defaults)
        modelContext.insert(tag)
        try modelContext.save()
        return tag
    }

    func update(
        _ tag: ReminderTag,
        name: String,
        colorToken: ReminderTagColorToken,
        symbolName: String,
        in modelContext: ModelContext,
        now: Date = .now
    ) throws {
        let displayName = try validatedDisplayName(name, excluding: tag.id, in: modelContext)
        let oldNormalizedName = tag.normalizedName
        let newNormalizedName = ReminderTag.normalizedName(from: displayName)

        if oldNormalizedName != newNormalizedName {
            for series in try modelContext.fetch(FetchDescriptor<ReminderSeries>()) {
                series.replaceTemplateTag(named: oldNormalizedName, with: newNormalizedName, now: now)
            }
            tag.rename(to: displayName)
        }
        tag.setAppearance(colorToken: colorToken, symbolName: symbolName)
        try modelContext.save()
    }

    func delete(_ tag: ReminderTag, in modelContext: ModelContext, now: Date = .now) throws {
        for series in try modelContext.fetch(FetchDescriptor<ReminderSeries>()) {
            series.replaceTemplateTag(named: tag.normalizedName, with: nil, now: now)
        }
        DefaultReminderTagSeeder.suppressDefault(for: tag, defaults: defaults)
        modelContext.delete(tag)
        try modelContext.save()
    }

    private func validatedDisplayName(
        _ name: String,
        excluding tagID: UUID?,
        in modelContext: ModelContext
    ) throws -> String {
        if let error = ReminderTag.validationError(for: name) {
            throw ReminderTagManagementError.invalidName(error)
        }

        let displayName = ReminderTag.displayName(from: name)
        let normalizedName = ReminderTag.normalizedName(from: displayName)
        let tags = try modelContext.fetch(FetchDescriptor<ReminderTag>())
        if tags.contains(where: { $0.id != tagID && $0.normalizedName == normalizedName }) {
            throw ReminderTagManagementError.duplicateName
        }
        return displayName
    }
}
