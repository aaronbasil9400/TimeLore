import SwiftUI

struct ReminderTagPresentation {
    let color: Color
    let symbol: String

    static func forTag(_ tag: ReminderTag) -> Self {
        Self(color: color(for: tag.colorToken), symbol: tag.resolvedSymbolName)
    }

    static func forTag(named name: String) -> Self {
        Self(color: color(for: ReminderTag.deterministicColorToken(for: name)), symbol: "tag")
    }

    static func color(for token: ReminderTagColorToken) -> Color {
        switch token {
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .red: .red
        case .orange: .orange
        case .green: .green
        case .mint: .mint
        case .teal: .teal
        case .cyan: .cyan
        case .brown: .brown
        case .gray: .gray
        }
    }
}
