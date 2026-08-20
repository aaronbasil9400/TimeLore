import Foundation
import SwiftData
import SwiftUI

enum AppIdentity {
    /// Reads the display name from the Xcode build setting so branding has one source of truth.
    static var displayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "TimeLore"
    }
}

@main
struct TimeLoreApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var notificationService = ReminderNotificationService()

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("-ui-testing")

        if arguments.contains("-reset-ui-testing-state") {
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "reminderSections.open.expanded")
            defaults.removeObject(forKey: "reminderSections.completed.expanded")
            defaults.removeObject(forKey: "reminderSections.archived.expanded")
        }

        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: isUITesting)
            modelContainer = try ModelContainer(
                for: Reminder.self,
                ReminderTag.self,
                ReminderSeries.self,
                ReminderAttachment.self,
                configurations: configuration
            )
            try DefaultReminderTagSeeder.seed(in: modelContainer.mainContext)
            try modelContainer.mainContext.save()
        } catch {
            fatalError("Unable to create the local reminder store: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ReminderListView()
                .environmentObject(notificationService)
        }
        .modelContainer(modelContainer)
    }
}
