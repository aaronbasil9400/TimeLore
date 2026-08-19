import Foundation
import Testing
@testable import TimeLore

@MainActor
struct ReminderNotificationPolicyTests {
    @Test func futureOpenReminderRequestsAndSchedulesOneNotification() async {
        let client = FakeNotificationClient(authorization: .notDetermined, requestedAuthorization: .authorized)
        let service = ReminderNotificationService(client: client)
        let reminder = Reminder(draft: ReminderDraft(title: "Call Maya", reason: "Confirm details", dueAt: .now.addingTimeInterval(3_600)))

        let showsGuidance = await service.reconcile(reminder, requestAuthorizationIfNeeded: true)

        #expect(!showsGuidance)
        #expect(client.requestCount == 1)
        #expect(client.scheduledIDs == [reminder.id.uuidString])
    }

    @Test func completedOrPastReminderCancelsNotification() async {
        let client = FakeNotificationClient(authorization: .authorized)
        let service = ReminderNotificationService(client: client)
        let reminder = Reminder(draft: ReminderDraft(title: "Call Maya", dueAt: .now.addingTimeInterval(3_600)))
        reminder.complete()

        _ = await service.reconcile(reminder, requestAuthorizationIfNeeded: false)

        #expect(client.scheduledIDs.isEmpty)
        #expect(client.cancelledIDs == [reminder.id.uuidString])
    }

    @Test func deniedPermissionDoesNotBlockSavingOrSchedule() async {
        let client = FakeNotificationClient(authorization: .denied)
        let service = ReminderNotificationService(client: client)
        let reminder = Reminder(draft: ReminderDraft(title: "Call Maya", dueAt: .now.addingTimeInterval(3_600)))

        let showsGuidance = await service.reconcile(reminder, requestAuthorizationIfNeeded: false)

        #expect(showsGuidance)
        #expect(client.scheduledIDs.isEmpty)
    }
}

@MainActor
private final class FakeNotificationClient: ReminderNotificationClient {
    private var authorization: ReminderNotificationAuthorization
    private let requestedAuthorization: ReminderNotificationAuthorization
    private(set) var requestCount = 0
    private(set) var scheduledIDs: [String] = []
    private(set) var cancelledIDs: [String] = []

    init(authorization: ReminderNotificationAuthorization, requestedAuthorization: ReminderNotificationAuthorization = .denied) {
        self.authorization = authorization
        self.requestedAuthorization = requestedAuthorization
    }

    func authorizationStatus() async -> ReminderNotificationAuthorization { authorization }

    func requestAuthorization() async -> ReminderNotificationAuthorization {
        requestCount += 1
        authorization = requestedAuthorization
        return authorization
    }

    func schedule(reminderID: String, title: String, reason: String, dueAt: Date) async {
        scheduledIDs.append(reminderID)
    }

    func cancel(reminderID: String) async {
        cancelledIDs.append(reminderID)
    }
}
