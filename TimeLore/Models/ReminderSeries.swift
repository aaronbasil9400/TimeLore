import Foundation
import SwiftData

enum ReminderRepeatFrequency: String, Codable, CaseIterable, Sendable {
    case weekly
    case monthly
    case yearly

    var title: String {
        rawValue.capitalized
    }
}

struct ReminderRepeatRule: Codable, Equatable, Sendable {
    var frequency: ReminderRepeatFrequency
    /// Calendar weekday: 1 is Sunday and 7 is Saturday.
    var weekday: Int?
    /// The requested day is clamped to the last valid day of a shorter month.
    var dayOfMonth: Int?
    var month: Int?
    var hour: Int
    var minute: Int

    init(frequency: ReminderRepeatFrequency, weekday: Int? = nil, dayOfMonth: Int? = nil, month: Int? = nil, hour: Int, minute: Int) {
        self.frequency = frequency
        self.weekday = weekday
        self.dayOfMonth = dayOfMonth
        self.month = month
        self.hour = hour
        self.minute = minute
    }

    static func from(dueAt: Date, frequency: ReminderRepeatFrequency, calendar: Calendar = .current) -> ReminderRepeatRule {
        let components = calendar.dateComponents([.weekday, .day, .month, .hour, .minute], from: dueAt)
        return ReminderRepeatRule(
            frequency: frequency,
            weekday: components.weekday,
            dayOfMonth: components.day,
            month: components.month,
            hour: components.hour ?? 9,
            minute: components.minute ?? 0
        )
    }

    var isValid: Bool {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return false }
        switch frequency {
        case .weekly:
            return (1...7).contains(weekday ?? 0)
        case .monthly:
            return (1...31).contains(dayOfMonth ?? 0)
        case .yearly:
            return (1...12).contains(month ?? 0) && (1...31).contains(dayOfMonth ?? 0)
        }
    }

    func summary(calendar: Calendar = .current) -> String {
        switch frequency {
        case .weekly:
            let weekdays = calendar.weekdaySymbols
            let name = weekdays[safe: (weekday ?? 1) - 1] ?? "selected day"
            return "Every week on \(name)"
        case .monthly:
            return "Every month on day \(dayOfMonth ?? 1)"
        case .yearly:
            let months = calendar.monthSymbols
            let name = months[safe: (month ?? 1) - 1] ?? "selected month"
            return "Every year in \(name) on day \(dayOfMonth ?? 1)"
        }
    }

    func nextDate(after date: Date, calendar: Calendar = .current) -> Date? {
        guard isValid else { return nil }
        switch frequency {
        case .weekly:
            return calendar.nextDate(
                after: date,
                matching: DateComponents(hour: hour, minute: minute, weekday: weekday),
                matchingPolicy: .nextTimePreservingSmallerComponents,
                repeatedTimePolicy: .first,
                direction: .forward
            )
        case .monthly:
            return nextMonthlyDate(after: date, calendar: calendar)
        case .yearly:
            return nextYearlyDate(after: date, calendar: calendar)
        }
    }

    private func nextMonthlyDate(after date: Date, calendar: Calendar) -> Date? {
        var components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year, let month = components.month else { return nil }
        guard let candidate = self.date(year: year, month: month, calendar: calendar) else { return nil }
        if candidate > date { return candidate }

        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: candidate) else { return nil }
        components = calendar.dateComponents([.year, .month], from: nextMonth)
        guard let nextYear = components.year, let nextMonthNumber = components.month else { return nil }
        return self.date(year: nextYear, month: nextMonthNumber, calendar: calendar)
    }

    private func nextYearlyDate(after date: Date, calendar: Calendar) -> Date? {
        let components = calendar.dateComponents([.year], from: date)
        guard let year = components.year, let month else { return nil }
        guard let candidate = self.date(year: year, month: month, calendar: calendar) else { return nil }
        if candidate > date { return candidate }
        return self.date(year: year + 1, month: month, calendar: calendar)
    }

    private func date(year: Int, month: Int, calendar: Calendar) -> Date? {
        guard let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let dayRange = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return nil
        }
        return calendar.date(from: DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: min(dayOfMonth ?? 1, dayRange.count),
            hour: hour,
            minute: minute
        ))
    }
}

@Model
final class ReminderSeries {
    @Attribute(.unique) var id: UUID
    var title: String
    var reason: String
    var isImportant: Bool
    var priorityRawValue: Int
    var repeatRuleData: Data
    var templateTagNamesData: Data
    var isStopped: Bool
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Reminder.recurrenceSeries)
    var occurrences: [Reminder] = []
    @Relationship(deleteRule: .cascade, inverse: \ReminderAttachment.series)
    var attachments: [ReminderAttachment] = []

    init(draft: ReminderDraft, tagNames: [String], now: Date = .now) {
        guard let repeatRule = draft.repeatRule else {
            preconditionFailure("A recurring series requires a repeat rule.")
        }

        id = UUID()
        title = draft.normalizedTitle
        reason = draft.normalizedReason
        isImportant = draft.isImportant
        priorityRawValue = draft.priority.rawValue
        repeatRuleData = (try? JSONEncoder().encode(repeatRule)) ?? Data()
        templateTagNamesData = (try? JSONEncoder().encode(tagNames.sorted())) ?? Data()
        isStopped = false
        createdAt = now
        updatedAt = now
    }

    var repeatRule: ReminderRepeatRule? {
        try? JSONDecoder().decode(ReminderRepeatRule.self, from: repeatRuleData)
    }

    var templateTagNames: [String] {
        (try? JSONDecoder().decode([String].self, from: templateTagNamesData)) ?? []
    }

    var priority: ReminderPriority {
        get { ReminderPriority(rawValue: priorityRawValue) ?? .none }
        set { priorityRawValue = newValue.rawValue }
    }

    func updateTemplate(from draft: ReminderDraft, tagNames: [String], now: Date = .now) {
        title = draft.normalizedTitle
        reason = draft.normalizedReason
        isImportant = draft.isImportant
        priority = draft.priority
        if let repeatRule = draft.repeatRule {
            repeatRuleData = (try? JSONEncoder().encode(repeatRule)) ?? repeatRuleData
            isStopped = false
        } else {
            isStopped = true
        }
        templateTagNamesData = (try? JSONEncoder().encode(tagNames.sorted())) ?? templateTagNamesData
        updatedAt = now
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
