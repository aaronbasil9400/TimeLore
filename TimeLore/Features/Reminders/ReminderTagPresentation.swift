import SwiftUI

struct ReminderTagPresentation {
    let color: Color
    let symbol: String

    static func forTag(named name: String) -> Self {
        switch ReminderTag.normalizedName(from: name) {
        case "work": return Self(color: .blue, symbol: "briefcase")
        case "personal": return Self(color: .purple, symbol: "person")
        case "projects": return Self(color: .indigo, symbol: "folder")
        case "grocery": return Self(color: .green, symbol: "cart")
        case "health": return Self(color: .pink, symbol: "heart")
        case "errands": return Self(color: .teal, symbol: "checklist")
        default:
            let palette: [(Color, String)] = [(.cyan, "tag"), (.mint, "tag"), (.orange, "tag"), (.brown, "tag")]
            let index = name.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % palette.count }
            return Self(color: palette[index].0, symbol: palette[index].1)
        }
    }
}
