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
    var archivedAt: Date?
    @Relationship(deleteRule: .nullify, inverse: \ReminderTag.reminders)
    var tags: [ReminderTag] = []

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
        archivedAt = nil
    }
}

extension Reminder {
    func update(from draft: ReminderDraft, tags: [ReminderTag], now: Date = .now) {
        title = draft.normalizedTitle
        reason = draft.normalizedReason
        dueAt = draft.dueAt
        self.tags = tags
        updatedAt = now
    }

    func complete(at date: Date = .now) {
        guard status != .completed else { return }
        status = .completed
        completedAt = date
        updatedAt = date
    }

    func reopen(at date: Date = .now) {
        guard status != .open else { return }
        status = .open
        completedAt = nil
        updatedAt = date
    }

    func archive(at date: Date = .now) {
        guard archivedAt == nil else { return }
        archivedAt = date
        updatedAt = date
    }

    func restore(at date: Date = .now) {
        guard archivedAt != nil else { return }
        archivedAt = nil
        updatedAt = date
    }

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

    static func completedSortOrder(_ lhs: Reminder, _ rhs: Reminder) -> Bool {
        (lhs.completedAt ?? .distantPast) > (rhs.completedAt ?? .distantPast)
    }

    static func archivedSortOrder(_ lhs: Reminder, _ rhs: Reminder) -> Bool {
        (lhs.archivedAt ?? .distantPast) > (rhs.archivedAt ?? .distantPast)
    }
}
