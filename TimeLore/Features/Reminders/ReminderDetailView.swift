import SwiftData
import SwiftUI

struct ReminderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var notificationService: ReminderNotificationService

    let reminder: Reminder

    @State private var isEditing = false
    @State private var isConfirmingDeletion = false

    private var sortedTags: [ReminderTag] {
        reminder.tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            Section {
                ReminderIdentityCard(reminder: reminder)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))

            Section("NOTES") {
                if reminder.reason.isEmpty {
                    Text("No notes added").foregroundStyle(.secondary)
                } else {
                    Text(reminder.reason)
                }
            }

            if let dueAt = reminder.dueAt {
                Section("Due") {
                    Label { Text(dueAt, format: .dateTime.weekday().month(.wide).day().year().hour().minute()) } icon: {
                        Image(systemName: "calendar")
                    }
                }
            }

            Section("Priority & Flag") {
                Toggle(isOn: Binding(
                    get: { reminder.isImportant },
                    set: { reminder.setImportant($0) }
                )) {
                    Label("Flag as Important", systemImage: "flag.fill")
                        .foregroundStyle(.orange)
                }
                .accessibilityIdentifier("detail.important")

                Picker("Priority", selection: Binding(
                    get: { reminder.priority },
                    set: { reminder.setPriority($0) }
                )) {
                    ForEach(ReminderPriority.allCases, id: \.self) { option in
                        Text(option == .none ? "None" : option.marker).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityValue(reminder.priority.accessibilityName)
            }

            if !sortedTags.isEmpty {
                Section("Tags") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sortedTags) { tag in ReminderTagChip(name: tag.name) }
                        }
                    }
                }
            }

            Section("History") {
                LabeledContent("Created") { Text(reminder.createdAt, format: .dateTime.month().day().year().hour().minute()) }
                LabeledContent("Updated") { Text(reminder.updatedAt, format: .dateTime.month().day().year().hour().minute()) }
                if let completedAt = reminder.completedAt {
                    LabeledContent("Completed") { Text(completedAt, format: .dateTime.month().day().year().hour().minute()) }
                }
                if let archivedAt = reminder.archivedAt {
                    LabeledContent("Archived") { Text(archivedAt, format: .dateTime.month().day().year().hour().minute()) }
                }
            }

            Section {
                Button(reminder.status == .completed ? "Reopen reminder" : "Mark as completed") {
                    if reminder.status == .completed { reminder.reopen() } else { reminder.complete() }
                    reconcileNotification()
                }
                .accessibilityIdentifier("detail.statusAction")
            }
        }
        .scrollContentBackground(.hidden)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .navigationTitle("Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit", systemImage: "pencil") { isEditing = true }
                    Button(reminder.isImportant ? "Unflag" : "Mark Important", systemImage: reminder.isImportant ? "flag.slash" : "flag") {
                        reminder.setImportant(!reminder.isImportant)
                    }
                    Button(reminder.archivedAt == nil ? "Archive" : "Restore", systemImage: reminder.archivedAt == nil ? "archivebox" : "arrow.uturn.backward") {
                        if reminder.archivedAt == nil { reminder.archive() } else { reminder.restore() }
                    }
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) { isConfirmingDeletion = true }
                } label: {
                    Label("More actions", systemImage: "ellipsis.circle")
                }
                .accessibilityIdentifier("detail.moreActions")
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack { ReminderEditorView(reminder: reminder) }
        }
        .alert("Delete this reminder?", isPresented: $isConfirmingDeletion) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: deleteReminder)
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func reconcileNotification() {
        Task { _ = await notificationService.reconcile(reminder, requestAuthorizationIfNeeded: false) }
    }

    private func deleteReminder() {
        Task {
            await notificationService.cancel(for: reminder)
            modelContext.delete(reminder)
            dismiss()
        }
    }
}

private struct ReminderIdentityCard: View {
    let reminder: Reminder

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("REMINDER")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(reminder.title)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
