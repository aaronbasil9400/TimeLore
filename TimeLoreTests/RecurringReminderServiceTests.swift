import Foundation
import SwiftData
import Testing
@testable import TimeLore

@MainActor
struct RecurringReminderServiceTests {
    @Test func completingAnOccurrenceCreatesExactlyOneSuccessorAndPreservesHistory() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let dueAt = utcDate(year: 2027, month: 1, day: 6, hour: 9)
        let rule = ReminderRepeatRule(frequency: .weekly, weekday: 4, hour: 9, minute: 0)
        let draft = ReminderDraft(title: "Weekly review", dueAt: dueAt, repeatRule: rule)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let service = RecurringReminderService(calendar: calendar)

        let first = service.createRecurringReminder(from: draft, tags: [], in: context, now: dueAt.addingTimeInterval(-60))
        let second = service.complete(first, in: context, now: dueAt)
        let duplicate = service.complete(first, in: context, now: dueAt.addingTimeInterval(1))

        #expect(first.status == .completed)
        #expect(first.completedAt == dueAt)
        #expect(second?.status == .open)
        #expect(second?.recurrenceIndex == 1)
        #expect(second?.recurrenceOccurrenceIdentifier == "\(first.recurrenceSeries!.id.uuidString).1")
        #expect(duplicate == nil)
        #expect(first.recurrenceSeries?.occurrences.count == 2)
    }

    @Test func thisOccurrenceEditLeavesTheSeriesTemplateUntouched() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let dueAt = utcDate(year: 2027, month: 5, day: 5, hour: 10)
        let rule = ReminderRepeatRule(frequency: .monthly, dayOfMonth: 5, hour: 10, minute: 0)
        let service = RecurringReminderService(calendar: utcCalendar)
        let first = service.createRecurringReminder(
            from: ReminderDraft(title: "Pay rent", reason: "Original", dueAt: dueAt, repeatRule: rule),
            tags: [],
            in: context
        )

        service.applyEdit(
            to: first,
            draft: ReminderDraft(title: "Pay rent today", reason: "One-off note", dueAt: dueAt.addingTimeInterval(3_600), repeatRule: rule),
            tags: [],
            scope: .thisOccurrence
        )

        #expect(first.title == "Pay rent today")
        #expect(first.recurrenceSeries?.title == "Pay rent")
        #expect(first.recurrenceSeries?.reason == "Original")
        #expect(first.scheduledAt == dueAt)
    }

    @Test func reopeningTheLatestOccurrenceRemovesOnlyItsGeneratedSuccessor() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let dueAt = utcDate(year: 2027, month: 6, day: 3, hour: 9)
        let rule = ReminderRepeatRule(frequency: .weekly, weekday: 5, hour: 9, minute: 0)
        let service = RecurringReminderService(calendar: utcCalendar)
        let first = service.createRecurringReminder(from: ReminderDraft(title: "Planning", dueAt: dueAt, repeatRule: rule), tags: [], in: context)
        let second = service.complete(first, in: context, now: dueAt)

        let removed = service.reopen(first, in: context, now: dueAt.addingTimeInterval(60))

        #expect(removed?.id == second?.id)
        #expect(first.status == .open)
        #expect(first.recurrenceSeries?.occurrences.filter { $0.status == .open }.count == 1)
    }

    @Test func thisAndFutureEditReschedulesAnAlreadyCreatedSuccessor() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let dueAt = utcDate(year: 2027, month: 8, day: 4, hour: 9)
        let originalRule = ReminderRepeatRule(frequency: .weekly, weekday: 4, hour: 9, minute: 0)
        let service = RecurringReminderService(calendar: utcCalendar)
        let first = service.createRecurringReminder(
            from: ReminderDraft(title: "Planning", dueAt: dueAt, repeatRule: originalRule),
            tags: [],
            in: context
        )
        let second = try #require(service.complete(first, in: context, now: dueAt))
        let editedDueAt = utcDate(year: 2027, month: 8, day: 4, hour: 10)
        let revisedRule = ReminderRepeatRule(frequency: .weekly, weekday: 4, hour: 10, minute: 0)

        let updated = service.applyEdit(
            to: first,
            draft: ReminderDraft(title: "Revised planning", dueAt: editedDueAt, repeatRule: revisedRule),
            tags: [],
            scope: .thisAndFuture,
            now: editedDueAt
        )

        #expect(updated?.id == second.id)
        #expect(second.title == "Revised planning")
        #expect(second.dueAt == utcDate(year: 2027, month: 8, day: 11, hour: 10))
        #expect(second.scheduledAt == second.dueAt)
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func utcDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
        utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Reminder.self,
            ReminderTag.self,
            ReminderSeries.self,
            ReminderAttachment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
