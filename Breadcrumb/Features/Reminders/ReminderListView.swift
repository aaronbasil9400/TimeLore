import SwiftData
import SwiftUI

struct ReminderListView: View {
    @Query(filter: #Predicate<Reminder> { $0.statusRawValue == "open" })
    private var reminders: [Reminder]

    @State private var isPresentingNewReminder = false

    private var orderedReminders: [Reminder] {
        reminders.sorted(by: Reminder.openSortOrder)
    }

    var body: some View {
        NavigationStack {
            Group {
                if orderedReminders.isEmpty {
                    ContentUnavailableView(
                        "No reminders yet",
                        systemImage: "checklist",
                        description: Text("Capture what you need to do and why it matters.")
                    )
                } else {
                    List(orderedReminders) { reminder in
                        ReminderRow(reminder: reminder)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Breadcrumb")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New reminder", systemImage: "plus") {
                        isPresentingNewReminder = true
                    }
                    .accessibilityHint("Creates a reminder with optional context and a due date")
                }
            }
            .sheet(isPresented: $isPresentingNewReminder) {
                NavigationStack {
                    ReminderEditorView()
                }
            }
        }
    }
}

private struct ReminderRow: View {
    let reminder: Reminder

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(reminder.title)
                .font(.headline)

            if !reminder.reason.isEmpty {
                Text(reminder.reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let dueAt = reminder.dueAt {
                Label {
                    Text(dueAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                } icon: {
                    Image(systemName: "calendar")
                }
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Empty reminders") {
    ReminderListView()
        .modelContainer(for: Reminder.self, inMemory: true)
}
