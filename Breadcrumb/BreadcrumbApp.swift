import Foundation
import SwiftData
import SwiftUI

@main
struct BreadcrumbApp: App {
    private let modelContainer: ModelContainer

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
                configurations: configuration
            )
        } catch {
            fatalError("Unable to create the local reminder store: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ReminderListView()
        }
        .modelContainer(modelContainer)
    }
}
