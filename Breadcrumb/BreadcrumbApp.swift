import SwiftData
import SwiftUI

@main
struct BreadcrumbApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Reminder.self)
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
