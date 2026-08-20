import Foundation
import SwiftData

enum ReminderStatus: String, Codable, Sendable {
    case open
    case completed
}

enum ReminderPriority: Int, Codable, CaseIterable, Sendable {
    case none = 0
    case level1 = 1
    case level2 = 2
    case level3 = 3

    var marker: String {
        String(repeating: "!", count: rawValue)
    }

    var accessibilityName: String {
        self == .none ? "No priority" : "Priority level \(rawValue), \(marker)"
    }
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
    var isImportant: Bool = false
    var priorityRawValue: Int = ReminderPriority.none.rawValue
    var recurrenceIndex: Int?
    var scheduledAt: Date?
    var recurrenceOccurrenceIdentifier: String?
    var recurrenceSeries: ReminderSeries?
    @Relationship(deleteRule: .nullify, inverse: \ReminderTag.reminders)
    var tags: [ReminderTag] = []
    @Relationship(deleteRule: .cascade, inverse: \ReminderAttachment.reminder)
    var attachments: [ReminderAttachment] = []

    var status: ReminderStatus {
        get { ReminderStatus(rawValue: statusRawValue) ?? .open }
        set { statusRawValue = newValue.rawValue }
    }

    var priority: ReminderPriority {
        get { ReminderPriority(rawValue: priorityRawValue) ?? .none }
        set { priorityRawValue = newValue.rawValue }
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
        isImportant = draft.isImportant
        priorityRawValue = draft.priority.rawValue
        recurrenceIndex = nil
        scheduledAt = nil
        recurrenceOccurrenceIdentifier = nil
    }
}

extension Reminder {
    func update(from draft: ReminderDraft, tags: [ReminderTag], now: Date = .now) {
        title = draft.normalizedTitle
        reason = draft.normalizedReason
        dueAt = draft.dueAt
        self.tags = tags
        isImportant = draft.isImportant
        priority = draft.priority
        updatedAt = now
    }

    var notificationIdentifier: String {
        recurrenceOccurrenceIdentifier ?? id.uuidString
    }

    var isRecurringOccurrence: Bool {
        recurrenceSeries != nil
    }

    var visibleAttachments: [ReminderAttachment] {
        recurrenceSeries?.attachments ?? attachments
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

    func setImportant(_ isImportant: Bool, at date: Date = .now) {
        guard self.isImportant != isImportant else { return }
        self.isImportant = isImportant
        updatedAt = date
    }

    func setPriority(_ priority: ReminderPriority, at date: Date = .now) {
        guard self.priority != priority else { return }
        self.priority = priority
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

    static func prioritySortOrder(_ lhs: Reminder, _ rhs: Reminder) -> Bool {
        if lhs.priorityRawValue != rhs.priorityRawValue {
            return lhs.priorityRawValue > rhs.priorityRawValue
        }
        return openSortOrder(lhs, rhs)
    }

    static func archivedSortOrder(_ lhs: Reminder, _ rhs: Reminder) -> Bool {
        (lhs.archivedAt ?? .distantPast) > (rhs.archivedAt ?? .distantPast)
    }
}
