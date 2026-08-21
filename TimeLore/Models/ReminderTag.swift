import Foundation
import SwiftData

enum ReminderTagColorToken: String, CaseIterable, Sendable {
    case blue
    case indigo
    case purple
    case pink
    case red
    case orange
    case green
    case mint
    case teal
    case cyan
    case brown
    case gray

    var accessibilityName: String {
        rawValue.capitalized
    }
}

@Model
final class ReminderTag {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var normalizedName: String
    var name: String
    var createdAt: Date
    var colorTokenRawValue: String?
    var symbolName: String?
    var defaultSeedKey: String?
    var reminders: [Reminder] = []

    init(
        name: String,
        colorToken: ReminderTagColorToken? = nil,
        symbolName: String? = nil,
        defaultSeedKey: String? = nil,
        createdAt: Date = .now
    ) {
        let displayName = Self.displayName(from: name)
        id = UUID()
        self.name = displayName
        normalizedName = Self.normalizedName(from: displayName)
        self.createdAt = createdAt
        colorTokenRawValue = (colorToken ?? Self.deterministicColorToken(for: displayName)).rawValue
        self.symbolName = symbolName ?? "tag"
        self.defaultSeedKey = defaultSeedKey
    }

    var colorToken: ReminderTagColorToken {
        ReminderTagColorToken(rawValue: colorTokenRawValue ?? "") ?? Self.deterministicColorToken(for: name)
    }

    var resolvedSymbolName: String {
        guard let symbolName, !symbolName.isEmpty else { return "tag" }
        return symbolName
    }

    func rename(to name: String) {
        let displayName = Self.displayName(from: name)
        self.name = displayName
        normalizedName = Self.normalizedName(from: displayName)
    }

    func setAppearance(colorToken: ReminderTagColorToken, symbolName: String) {
        colorTokenRawValue = colorToken.rawValue
        self.symbolName = symbolName
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

    static func deterministicColorToken(for name: String) -> ReminderTagColorToken {
        let palette: [ReminderTagColorToken] = [.cyan, .mint, .orange, .brown, .blue, .purple, .teal, .pink]
        let index = normalizedName(from: name).unicodeScalars.reduce(0) {
            ($0 + Int($1.value)) % palette.count
        }
        return palette[index]
    }
}
