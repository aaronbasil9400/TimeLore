import Foundation

struct ReminderDraft: Equatable, Sendable {
    var title: String = ""
    var reason: String = ""
    var dueAt: Date?

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedReason: String {
        reason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func validationError(now: Date = .now) -> String? {
        if normalizedTitle.isEmpty {
            return "Add a reminder title."
        }

        if normalizedTitle.count > 200 {
            return "Keep the title to 200 characters or fewer."
        }

        if normalizedReason.count > 2_000 {
            return "Keep the context to 2,000 characters or fewer."
        }

        if let dueAt, dueAt <= now {
            return "Choose a future date and time."
        }

        return nil
    }
}
