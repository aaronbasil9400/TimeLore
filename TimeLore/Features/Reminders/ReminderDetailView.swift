import QuickLook
import SwiftData
import SwiftUI

struct ReminderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var notificationService: ReminderNotificationService

    let reminder: Reminder
    private let attachmentStore = ReminderAttachmentStore()

    @State private var isEditing = false
    @State private var isChoosingEditScope = false
    @State private var recurringEditScope: RecurringReminderEditScope = .thisAndFuture
    @State private var isConfirmingDeletion = false
    @State private var isChoosingDeletionScope = false
    @State private var previewingAttachment: AttachmentPreviewItem?

    private var sortedTags: [ReminderTag] {
        reminder.tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var series: ReminderSeries? {
        reminder.recurrenceSeries
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

            if let series {
                Section("Repeat") {
                    if series.isStopped {
                        Label("Repeats stopped", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.secondary)
                    } else if let rule = series.repeatRule {
                        LabeledContent("Schedule") { Text(rule.summary()) }
                        let generatedNext = reminder.scheduledAt.flatMap { rule.nextDate(after: $0) }
                        let next = series.occurrences
                            .filter({ $0.status == .open && $0.id != reminder.id })
                            .sorted(by: Reminder.openSortOrder)
                            .first?.dueAt ?? generatedNext
                        if let next {
                            LabeledContent("Next") { Text(next, format: .dateTime.month().day().year().hour().minute()) }
                        }
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

            if !reminder.visibleAttachments.isEmpty {
                Section("Attachments") {
                    ForEach(reminder.visibleAttachments) { attachment in
                        AttachmentDetailRow(
                            attachment: attachment,
                            payloadURL: attachmentStore.payloadURL(for: attachment),
                            preview: { url in previewingAttachment = AttachmentPreviewItem(url: url) },
                            remove: { removeAttachment(attachment) }
                        )
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
                Button(reminder.status == .completed ? "Reopen reminder" : "Mark as completed", action: performStatusAction)
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
                    Button("Edit", systemImage: "pencil", action: beginEditing)
                    Button(reminder.isImportant ? "Unflag" : "Mark Important", systemImage: reminder.isImportant ? "flag.slash" : "flag") {
                        reminder.setImportant(!reminder.isImportant)
                    }
                    Button(reminder.archivedAt == nil ? "Archive" : "Restore", systemImage: reminder.archivedAt == nil ? "archivebox" : "arrow.uturn.backward") {
                        if reminder.archivedAt == nil { reminder.archive() } else { reminder.restore() }
                    }
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive, action: beginDeletion)
                } label: {
                    Label("More actions", systemImage: "ellipsis.circle")
                }
                .accessibilityIdentifier("detail.moreActions")
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack { ReminderEditorView(reminder: reminder, recurringEditScope: recurringEditScope) }
        }
        .confirmationDialog("Edit repeating reminder", isPresented: $isChoosingEditScope, titleVisibility: .visible) {
            Button("This occurrence") {
                recurringEditScope = .thisOccurrence
                isEditing = true
            }
            Button("This and future occurrences") {
                recurringEditScope = .thisAndFuture
                isEditing = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how the changes should affect this repeating reminder.")
        }
        .confirmationDialog("Delete repeating reminder", isPresented: $isChoosingDeletionScope, titleVisibility: .visible) {
            Button("Delete this occurrence", role: .destructive) { deleteThisOccurrence() }
            Button("Delete this and future occurrences", role: .destructive) { deleteThisAndFuture() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Completed history is kept when deleting this and future occurrences.")
        }
        .alert("Delete this reminder?", isPresented: $isConfirmingDeletion) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: deleteReminder)
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(item: $previewingAttachment) { item in
            AttachmentPreview(url: item.url)
        }
    }

    private func beginEditing() {
        guard reminder.isRecurringOccurrence else {
            isEditing = true
            return
        }
        isChoosingEditScope = true
    }

    private func beginDeletion() {
        isChoosingDeletionScope = reminder.isRecurringOccurrence
        if !reminder.isRecurringOccurrence { isConfirmingDeletion = true }
    }

    private func performStatusAction() {
        let recurrenceService = RecurringReminderService()
        if reminder.status == .completed {
            let removed = recurrenceService.reopen(reminder, in: modelContext)
            if let removed {
                Task { await notificationService.cancel(for: removed) }
            }
            reconcileNotification(for: reminder)
        } else {
            let next = recurrenceService.complete(reminder, in: modelContext)
            reconcileNotification(for: reminder)
            if let next { reconcileNotification(for: next) }
        }
    }

    private func reconcileNotification(for reminder: Reminder) {
        Task { _ = await notificationService.reconcile(reminder, requestAuthorizationIfNeeded: false) }
    }

    private func removeAttachment(_ attachment: ReminderAttachment) {
        attachmentStore.removePayload(for: attachment)
        modelContext.delete(attachment)
    }

    private func deleteThisOccurrence() {
        let recurrenceService = RecurringReminderService()
        Task {
            await notificationService.cancel(for: reminder)
            let replacement = recurrenceService.deleteThisOccurrence(reminder, in: modelContext)
            if let replacement {
                _ = await notificationService.reconcile(replacement, requestAuthorizationIfNeeded: false)
            }
            dismiss()
        }
    }

    private func deleteThisAndFuture() {
        let recurrenceService = RecurringReminderService()
        Task {
            let completedHistoryExists = series?.occurrences.contains { $0.status == .completed } ?? false
            let seriesAttachments = completedHistoryExists ? [] : (series?.attachments ?? [])
            let deleted = recurrenceService.deleteThisAndFuture(from: reminder, in: modelContext)
            for occurrence in deleted {
                await notificationService.cancel(for: occurrence)
            }
            if !completedHistoryExists, let series {
                for attachment in seriesAttachments {
                    attachmentStore.removePayload(for: attachment)
                }
                modelContext.delete(series)
            }
            dismiss()
        }
    }

    private func deleteReminder() {
        Task {
            await notificationService.cancel(for: reminder)
            for attachment in reminder.visibleAttachments {
                attachmentStore.removePayload(for: attachment)
            }
            modelContext.delete(reminder)
            dismiss()
        }
    }
}

private struct AttachmentDetailRow: View {
    let attachment: ReminderAttachment
    let payloadURL: URL?
    let preview: (URL) -> Void
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: attachment.kind.symbolName)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.displayName).lineLimit(1)
                Text("\(attachment.kind.title) · \(ByteCountFormatter.string(fromByteCount: attachment.byteCount, countStyle: .file))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if payloadURL == nil {
                    Text("Attachment unavailable")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Spacer()
            if let payloadURL {
                Button("Preview") { preview(payloadURL) }
                    .accessibilityLabel("Preview \(attachment.displayName)")
            }
            Button("Remove", role: .destructive, action: remove)
                .accessibilityLabel("Remove \(attachment.displayName)")
        }
        .accessibilityElement(children: .combine)
    }
}

private struct AttachmentPreviewItem: Identifiable {
    let url: URL
    var id: URL { url }
}

private struct AttachmentPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
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
