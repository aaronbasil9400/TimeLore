import Foundation
import SwiftData

@Model
final class ReminderTag {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var normalizedName: String
    var name: String
    var createdAt: Date
    var reminders: [Reminder] = []

    init(name: String, createdAt: Date = .now) {
        let displayName = Self.displayName(from: name)
        id = UUID()
        self.name = displayName
        normalizedName = Self.normalizedName(from: displayName)
        self.createdAt = createdAt
    }

    static func displayName(from name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizedName(from name: String) -> String {
        displayName(from: name).folding(
            options: [.caseInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    static func validationError(for name: String) -> String? {
        let displayName = displayName(from: name)

        if displayName.isEmpty {
            return "Enter a tag name."
        }

        if displayName.count > 30 {
            return "Keep tag names to 30 characters or fewer."
        }

        return nil
    }
}
