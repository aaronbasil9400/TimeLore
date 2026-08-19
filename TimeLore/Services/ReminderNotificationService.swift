import Foundation
import UserNotifications

enum ReminderNotificationAuthorization: Equatable {
    case notDetermined
    case authorized
    case denied
}

protocol ReminderNotificationClient {
    func authorizationStatus() async -> ReminderNotificationAuthorization
    func requestAuthorization() async -> ReminderNotificationAuthorization
    func schedule(reminderID: String, title: String, reason: String, dueAt: Date) async
    func cancel(reminderID: String) async
}

struct SystemReminderNotificationClient: ReminderNotificationClient {
    private let center = UNUserNotificationCenter.current()

    func authorizationStatus() async -> ReminderNotificationAuthorization {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .notDetermined:
            return .notDetermined
        default:
            return .denied
        }
    }

    func requestAuthorization() async -> ReminderNotificationAuthorization {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted ? .authorized : .denied
        } catch {
            return .denied
        }
    }

    func schedule(reminderID: String, title: String, reason: String, dueAt: Date) async {
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = reason.isEmpty ? "Reminder due now" : reason
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.calendar, .timeZone, .year, .month, .day, .hour, .minute], from: dueAt),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancel(reminderID: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])
    }
}

enum ReminderNotificationPolicy {
    static func shouldSchedule(_ reminder: Reminder, now: Date = .now) -> Bool {
        reminder.status == .open && (reminder.dueAt ?? .distantPast) > now
    }
}

@MainActor
final class ReminderNotificationService: ObservableObject {
    private let client: any ReminderNotificationClient

    init(client: any ReminderNotificationClient = SystemReminderNotificationClient()) {
        self.client = client
    }

    /// Returns true only when a user-facing denied-permission callout should be shown.
    func reconcile(_ reminder: Reminder, requestAuthorizationIfNeeded: Bool) async -> Bool {
        guard ReminderNotificationPolicy.shouldSchedule(reminder) else {
            await client.cancel(reminderID: reminder.id.uuidString)
            return false
        }

        var authorization = await client.authorizationStatus()
        if authorization == .notDetermined, requestAuthorizationIfNeeded {
            authorization = await client.requestAuthorization()
        }

        guard authorization == .authorized, let dueAt = reminder.dueAt else {
            return authorization == .denied
        }

        await client.schedule(
            reminderID: reminder.id.uuidString,
            title: reminder.title,
            reason: reminder.reason,
            dueAt: dueAt
        )
        return false
    }

    func cancel(for reminder: Reminder) async {
        await client.cancel(reminderID: reminder.id.uuidString)
    }
}
