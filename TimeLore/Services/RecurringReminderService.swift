import Foundation
import SwiftData

enum RecurringReminderEditScope: Sendable {
    case thisOccurrence
    case thisAndFuture
}

@MainActor
struct RecurringReminderService {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func createRecurringReminder(
        from draft: ReminderDraft,
        tags: [ReminderTag],
        in modelContext: ModelContext,
        now: Date = .now
    ) -> Reminder {
        precondition(draft.repeatRule != nil && draft.dueAt != nil)

        let series = ReminderSeries(draft: draft, tagNames: tags.map(\.normalizedName), now: now)
        modelContext.insert(series)
        let occurrence = makeOccurrence(
            from: series,
            dueAt: draft.dueAt!,
            index: 0,
            tags: tags,
            now: now
        )
        modelContext.insert(occurrence)
        occurrence.recurrenceSeries = series
        return occurrence
    }

    /// Converts an existing one-time reminder into the first occurrence of a new series.
    func startRecurrence(
        for reminder: Reminder,
        draft: ReminderDraft,
        tags: [ReminderTag],
        in modelContext: ModelContext,
        now: Date = .now
    ) {
        guard let dueAt = draft.dueAt, draft.repeatRule != nil else { return }
        let series = ReminderSeries(draft: draft, tagNames: tags.map(\.normalizedName), now: now)
        modelContext.insert(series)
        reminder.update(from: draft, tags: tags, now: now)
        reminder.recurrenceIndex = 0
        reminder.scheduledAt = dueAt
        reminder.recurrenceOccurrenceIdentifier = "\(series.id.uuidString).0"
        reminder.recurrenceSeries = series
        for attachment in Array(reminder.attachments) {
            attachment.reminder = nil
            attachment.series = series
        }
    }

    /// Completes an occurrence and creates exactly one pending successor when the series is active.
    @discardableResult
    func complete(_ reminder: Reminder, in modelContext: ModelContext, now: Date = .now) -> Reminder? {
        guard reminder.status == .open else { return nil }
        reminder.complete(at: now)

        guard let series = reminder.recurrenceSeries,
              !series.isStopped,
              let rule = series.repeatRule,
              let index = reminder.recurrenceIndex,
              let scheduledAt = reminder.scheduledAt,
              let nextDueAt = rule.nextDate(after: scheduledAt, calendar: calendar) else {
            return nil
        }

        let nextIndex = index + 1
        if let existing = series.occurrences.first(where: { $0.recurrenceIndex == nextIndex }) {
            return existing
        }

        let occurrence = makeOccurrence(
            from: series,
            dueAt: nextDueAt,
            index: nextIndex,
            tags: resolvedTags(named: series.templateTagNames, in: modelContext),
            now: now
        )
        modelContext.insert(occurrence)
        occurrence.recurrenceSeries = series
        return occurrence
    }

    /// Reopening the latest completed occurrence removes its generated successor so there is only one scheduled occurrence.
    @discardableResult
    func reopen(_ reminder: Reminder, in modelContext: ModelContext, now: Date = .now) -> Reminder? {
        guard reminder.status == .completed else { return nil }
        var removedSuccessor: Reminder?

        if let series = reminder.recurrenceSeries, let index = reminder.recurrenceIndex,
           let successor = series.occurrences.first(where: { $0.recurrenceIndex == index + 1 && $0.status == .open }) {
            series.occurrences.removeAll { $0.id == successor.id }
            modelContext.delete(successor)
            removedSuccessor = successor
        }

        reminder.reopen(at: now)
        return removedSuccessor
    }

    /// Returns an already-created future occurrence when the edit also changes it.
    @discardableResult
    func applyEdit(
        to reminder: Reminder,
        draft: ReminderDraft,
        tags: [ReminderTag],
        scope: RecurringReminderEditScope,
        now: Date = .now
    ) -> Reminder? {
        reminder.update(from: draft, tags: tags, now: now)

        guard let series = reminder.recurrenceSeries else { return nil }
        switch scope {
        case .thisOccurrence:
            // Its stored scheduledAt remains the series position used to generate future occurrences.
            return nil
        case .thisAndFuture:
            series.updateTemplate(from: draft, tagNames: tags.map(\.normalizedName), now: now)
            reminder.scheduledAt = draft.dueAt

            // A completed occurrence already has one open successor. Keep that
            // successor, its notification, and the new series template aligned.
            guard reminder.status == .completed,
                  let index = reminder.recurrenceIndex,
                  let scheduledAt = reminder.scheduledAt,
                  let rule = series.repeatRule,
                  let successor = series.occurrences.first(where: {
                      $0.recurrenceIndex == index + 1 && $0.status == .open
                  }),
                  let successorDueAt = rule.nextDate(after: scheduledAt, calendar: calendar) else {
                return nil
            }

            let successorDraft = ReminderDraft(
                title: series.title,
                reason: series.reason,
                dueAt: successorDueAt,
                isImportant: series.isImportant,
                priority: series.priority,
                repeatRule: rule
            )
            successor.update(from: successorDraft, tags: tags, now: now)
            successor.scheduledAt = successorDueAt
            return successor
        }
    }

    /// Stops future generation without touching completed occurrence history or series attachments.
    func stopRecurrence(for reminder: Reminder, now: Date = .now) {
        guard let series = reminder.recurrenceSeries else { return }
        series.isStopped = true
        series.updatedAt = now
    }

    /// Removes one occurrence. Removing the open occurrence of an active series creates its next scheduled successor.
    @discardableResult
    func deleteThisOccurrence(_ reminder: Reminder, in modelContext: ModelContext, now: Date = .now) -> Reminder? {
        guard let series = reminder.recurrenceSeries,
              !series.isStopped,
              reminder.status == .open,
              let index = reminder.recurrenceIndex,
              let scheduledAt = reminder.scheduledAt,
              let rule = series.repeatRule,
              let nextDueAt = rule.nextDate(after: scheduledAt, calendar: calendar) else {
            modelContext.delete(reminder)
            return nil
        }

        let nextIndex = index + 1
        let existing = series.occurrences.first(where: { $0.recurrenceIndex == nextIndex })
        let replacement = existing ?? makeOccurrence(
            from: series,
            dueAt: nextDueAt,
            index: nextIndex,
            tags: resolvedTags(named: series.templateTagNames, in: modelContext),
            now: now
        )
        if existing == nil {
            modelContext.insert(replacement)
            series.occurrences.append(replacement)
        }
        series.occurrences.removeAll { $0.id == reminder.id }
        modelContext.delete(reminder)
        return replacement
    }

    /// Stops the series and deletes pending occurrences while keeping completed history intact.
    func deleteThisAndFuture(from reminder: Reminder, in modelContext: ModelContext, now: Date = .now) -> [Reminder] {
        guard let series = reminder.recurrenceSeries else {
            modelContext.delete(reminder)
            return [reminder]
        }
        series.isStopped = true
        series.updatedAt = now

        let pending = series.occurrences.filter { $0.status == .open }
        for occurrence in pending {
            series.occurrences.removeAll { $0.id == occurrence.id }
            modelContext.delete(occurrence)
        }
        return pending
    }

    private func makeOccurrence(
        from series: ReminderSeries,
        dueAt: Date,
        index: Int,
        tags: [ReminderTag],
        now: Date
    ) -> Reminder {
        let draft = ReminderDraft(
            title: series.title,
            reason: series.reason,
            dueAt: dueAt,
            isImportant: series.isImportant,
            priority: series.priority,
            repeatRule: series.repeatRule
        )
        let occurrence = Reminder(draft: draft, now: now)
        occurrence.recurrenceIndex = index
        occurrence.scheduledAt = dueAt
        occurrence.recurrenceOccurrenceIdentifier = "\(series.id.uuidString).\(index)"
        occurrence.tags = tags
        return occurrence
    }

    private func resolvedTags(named normalizedNames: [String], in modelContext: ModelContext) -> [ReminderTag] {
        guard !normalizedNames.isEmpty,
              let allTags = try? modelContext.fetch(FetchDescriptor<ReminderTag>()) else {
            return []
        }
        return allTags.filter { normalizedNames.contains($0.normalizedName) }
    }
}
