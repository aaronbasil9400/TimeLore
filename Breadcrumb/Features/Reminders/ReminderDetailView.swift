import SwiftData
import SwiftUI

struct ReminderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let reminder: Reminder

    @State private var isEditing = false
    @State private var isConfirmingDeletion = false

    private var sortedTags: [ReminderTag] {
        reminder.tags.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var body: some View {
        List {
            Section("Reminder") {
                Text(reminder.title)
                    .font(.title3.weight(.semibold))

                if reminder.reason.isEmpty {
                    Text("No context added")
                        .foregroundStyle(.secondary)
                } else {
                    Text(reminder.reason)
                }
            }

            if let dueAt = reminder.dueAt {
                Section("Due") {
                    Label {
                        Text(dueAt, format: .dateTime.weekday().month(.wide).day().year().hour().minute())
                    } icon: {
                        Image(systemName: "calendar")
                    }
                }
            }

            if !sortedTags.isEmpty {
                Section("Tags") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sortedTags) { tag in
                                ReminderTagChip(name: tag.name)
                            }
                        }
                    }
                }
            }

            Section("History") {
                LabeledContent("Created") {
                    Text(reminder.createdAt, format: .dateTime.month().day().year().hour().minute())
                }
                LabeledContent("Updated") {
                    Text(reminder.updatedAt, format: .dateTime.month().day().year().hour().minute())
                }
                if let completedAt = reminder.completedAt {
                    LabeledContent("Completed") {
                        Text(completedAt, format: .dateTime.month().day().year().hour().minute())
                    }
                }
                if let archivedAt = reminder.archivedAt {
                    LabeledContent("Archived") {
                        Text(archivedAt, format: .dateTime.month().day().year().hour().minute())
                    }
                }
            }

            Section("Actions") {
                Button(reminder.status == .completed ? "Reopen reminder" : "Mark as completed") {
                    if reminder.status == .completed {
                        reminder.reopen()
                    } else {
                        reminder.complete()
                    }
                }

                Button(reminder.archivedAt == nil ? "Archive reminder" : "Restore reminder") {
                    if reminder.archivedAt == nil {
                        reminder.archive()
                    } else {
                        reminder.restore()
                    }
                }

                Button("Delete reminder", role: .destructive) {
                    isConfirmingDeletion = true
                }
            }
        }
        .navigationTitle("Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                ReminderEditorView(reminder: reminder)
            }
        }
        .alert("Delete this reminder?", isPresented: $isConfirmingDeletion) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: deleteReminder)
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func deleteReminder() {
        modelContext.delete(reminder)
        dismiss()
    }
}
