import Foundation
import SwiftData

enum ReminderStatus: String, Codable, Sendable {
    case open
    case completed
}

@Model
final class Reminder {
    @Attribute(.unique) var id: UUID
    var title: String
    var reason: String
    var dueAt: Date?
    var statusRawValue: String
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    var status: ReminderStatus {
        get { ReminderStatus(rawValue: statusRawValue) ?? .open }
        set { statusRawValue = newValue.rawValue }
    }

    init(draft: ReminderDraft, now: Date = .now) {
        id = UUID()
        title = draft.normalizedTitle
        reason = draft.normalizedReason
        dueAt = draft.dueAt
        statusRawValue = ReminderStatus.open.rawValue
        createdAt = now
        updatedAt = now
        completedAt = nil
    }
}

extension Reminder {
    static func openSortOrder(_ lhs: Reminder, _ rhs: Reminder) -> Bool {
        switch (lhs.dueAt, rhs.dueAt) {
        case let (left?, right?):
            return left == right ? lhs.createdAt > rhs.createdAt : left < right
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return lhs.createdAt > rhs.createdAt
        }
    }
}
