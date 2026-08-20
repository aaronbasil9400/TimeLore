import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ReminderEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var notificationService: ReminderNotificationService
    @Query(sort: \ReminderTag.name) private var availableTags: [ReminderTag]

    private let reminder: Reminder?
    private let originalDueAt: Date?
    private let recurringEditScope: RecurringReminderEditScope
    private let attachmentStore = ReminderAttachmentStore()

    @State private var title: String
    @State private var reason: String
    @State private var includesDueDate: Bool
    @State private var dueAt: Date
    @State private var isImportant: Bool
    @State private var priority: ReminderPriority
    @State private var repeatFrequency: ReminderRepeatFrequency?
    @State private var repeatWeekday: Int
    @State private var repeatDayOfMonth: Int
    @State private var repeatMonth: Int
    @State private var selectedTagNames: Set<String>
    @State private var pendingTagNames: [String: String] = [:]
    @State private var newTagName = ""
    @State private var draftAttachments: [ReminderAttachmentDraft] = []
    @State private var removedAttachmentIDs = Set<UUID>()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isPresentingFileImporter = false
    @State private var validationMessage: String?
    @State private var tagValidationMessage: String?
    @State private var attachmentMessage: String?
    @State private var isShowingNotificationGuidance = false
    @AppStorage("notifications.permissionPrompted") private var hasPromptedForNotifications = false

    init(reminder: Reminder? = nil, recurringEditScope: RecurringReminderEditScope = .thisAndFuture) {
        self.reminder = reminder
        self.recurringEditScope = recurringEditScope
        originalDueAt = reminder?.dueAt
        let existingRule = reminder?.recurrenceSeries?.isStopped == false ? reminder?.recurrenceSeries?.repeatRule : nil
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday, .day, .month], from: reminder?.dueAt ?? .now)
        _title = State(initialValue: reminder?.title ?? "")
        _reason = State(initialValue: reminder?.reason ?? "")
        _includesDueDate = State(initialValue: reminder?.dueAt != nil)
        _dueAt = State(initialValue: reminder?.dueAt ?? Date.now.addingTimeInterval(60 * 60))
        _isImportant = State(initialValue: reminder?.isImportant ?? false)
        _priority = State(initialValue: reminder?.priority ?? .none)
        _repeatFrequency = State(initialValue: existingRule?.frequency)
        _repeatWeekday = State(initialValue: existingRule?.weekday ?? components.weekday ?? 1)
        _repeatDayOfMonth = State(initialValue: existingRule?.dayOfMonth ?? components.day ?? 1)
        _repeatMonth = State(initialValue: existingRule?.month ?? components.month ?? 1)
        _selectedTagNames = State(initialValue: Set(reminder?.tags.map(\.normalizedName) ?? []))
    }

    private var draft: ReminderDraft {
        ReminderDraft(
            title: title,
            reason: reason,
            dueAt: includesDueDate ? dueAt : nil,
            isImportant: isImportant,
            priority: priority,
            repeatRule: repeatRule
        )
    }

    private var repeatRule: ReminderRepeatRule? {
        guard includesDueDate, let repeatFrequency else { return nil }
        let time = Calendar.current.dateComponents([.hour, .minute], from: dueAt)
        return ReminderRepeatRule(
            frequency: repeatFrequency,
            weekday: repeatWeekday,
            dayOfMonth: repeatDayOfMonth,
            month: repeatMonth,
            hour: time.hour ?? 9,
            minute: time.minute ?? 0
        )
    }

    private var isEditingOnlyOneOccurrence: Bool {
        reminder?.isRecurringOccurrence == true && recurringEditScope == .thisOccurrence
    }

    private var savedAttachments: [ReminderAttachment] {
        (reminder?.visibleAttachments ?? []).filter { !removedAttachmentIDs.contains($0.id) }
    }

    private var attachmentsMarkedForRemoval: [ReminderAttachment] {
        (reminder?.visibleAttachments ?? []).filter { removedAttachmentIDs.contains($0.id) }
    }

    private var attachmentCount: Int {
        savedAttachments.count + draftAttachments.count
    }

    private var attachmentByteCount: Int64 {
        savedAttachments.reduce(0) { $0 + $1.byteCount } + draftAttachments.reduce(0) { $0 + $1.byteCount }
    }

    private var tagOptions: [TagOption] {
        var options = Dictionary(
            uniqueKeysWithValues: availableTags.map {
                ($0.normalizedName, TagOption(id: $0.normalizedName, name: $0.name))
            }
        )

        for (normalizedName, displayName) in pendingTagNames {
            options[normalizedName] = TagOption(id: normalizedName, name: displayName)
        }

        return options.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var body: some View {
        Form {
            Section("Reminder") {
                TextField("What do you need to do?", text: $title, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(1...3)
                    .accessibilityLabel("Reminder title")
                    .accessibilityIdentifier("reminder.title")

                TextField("Notes", text: $reason, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(3...8)
                    .accessibilityLabel("Reminder notes")
                    .accessibilityIdentifier("reminder.reason")
            }

            Section("When") {
                Toggle("Set a due date", isOn: $includesDueDate.animation())

                if includesDueDate {
                    DatePicker(
                        "Due",
                        selection: $dueAt,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    if isEditingOnlyOneOccurrence {
                        LabeledContent("Repeat") {
                            Text(reminder?.recurrenceSeries?.repeatRule?.summary() ?? "Repeats")
                                .foregroundStyle(.secondary)
                        }
                        Text("Changes to this occurrence do not alter the repeat schedule.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Repeat", selection: $repeatFrequency) {
                            Text("Does not repeat").tag(ReminderRepeatFrequency?.none)
                            ForEach(ReminderRepeatFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.title).tag(Optional(frequency))
                            }
                        }
                        .accessibilityIdentifier("reminder.repeat")

                        if let repeatFrequency {
                            repeatControls(for: repeatFrequency)
                            Text(repeatRule?.summary() ?? "")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Priority & Flag") {
                Toggle("Flag as Important", isOn: $isImportant)
                    .accessibilityIdentifier("reminder.important")

                Picker("Priority", selection: $priority) {
                    ForEach(ReminderPriority.allCases, id: \.self) { option in
                        Text(option == .none ? "None" : option.marker).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Priority")
                .accessibilityValue(priority.accessibilityName)
            }

            Section("Tags") {
                if !tagOptions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tagOptions) { option in
                                Button {
                                    toggleTag(option.id)
                                } label: {
                                    ReminderTagChip(
                                        name: option.name,
                                        isSelected: selectedTagNames.contains(option.id)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Tag \(option.name)")
                                .accessibilityValue(selectedTagNames.contains(option.id) ? "Selected" : "Not selected")
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                HStack {
                    TextField("New tag", text: $newTagName)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit(addTag)
                        .accessibilityIdentifier("tag.newName")

                    Button("Add", action: addTag)
                        .disabled(ReminderTag.displayName(from: newTagName).isEmpty)
                }

                if let tagValidationMessage {
                    Text(tagValidationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Attachments") {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Add Photo", systemImage: "photo")
                }
                .accessibilityIdentifier("attachment.addPhoto")

                Button("Add File", systemImage: "doc.badge.plus") {
                    isPresentingFileImporter = true
                }
                .accessibilityIdentifier("attachment.addFile")

                if attachmentCount == 0 {
                    Text("Up to 6 attachments, 15 MB total.")
                        .foregroundStyle(.secondary)
                }

                ForEach(savedAttachments) { attachment in
                    AttachmentEditorRow(
                        title: attachment.displayName,
                        subtitle: "\(attachment.kind.title) · \(ByteCountFormatter.string(fromByteCount: attachment.byteCount, countStyle: .file))",
                        kind: attachment.kind,
                        thumbnailURL: attachmentStore.payloadURL(for: attachment)
                    ) {
                        removedAttachmentIDs.insert(attachment.id)
                    }
                }

                ForEach(draftAttachments) { attachment in
                    AttachmentEditorRow(
                        title: attachment.displayName,
                        subtitle: "\(attachment.kind.title) · \(ByteCountFormatter.string(fromByteCount: attachment.byteCount, countStyle: .file))",
                        kind: attachment.kind,
                        thumbnailURL: attachmentStore.stagingURL(for: attachment)
                    ) {
                        removeDraftAttachment(attachment)
                    }
                }

                if attachmentCount > 0 {
                    Text("\(attachmentCount) of 6 · \(ByteCountFormatter.string(fromByteCount: attachmentByteCount, countStyle: .file)) of 15 MB")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let attachmentMessage {
                    Text(attachmentMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                        .accessibilityAddTraits(.isStaticText)
                }
            }
        }
        .navigationTitle(reminder == nil ? "New reminder" : "Edit reminder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: cancel)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .accessibilityHint("Saves this reminder locally")
                    .accessibilityIdentifier("reminder.save")
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            importPhoto(item)
        }
        .onChange(of: dueAt) { _, newValue in
            if repeatFrequency == .yearly {
                repeatDayOfMonth = Calendar.current.component(.day, from: newValue)
            }
        }
        .fileImporter(isPresented: $isPresentingFileImporter, allowedContentTypes: [.item]) { result in
            guard case let .success(url) = result else { return }
            importFile(url)
        }
        .onDisappear {
            attachmentStore.discard(draftAttachments)
        }
        .alert("Notifications are off", isPresented: $isShowingNotificationGuidance) {
            Button("Open Settings") {
                openURL(URL(string: UIApplication.openSettingsURLString)!)
                dismiss()
            }
            Button("Continue") { dismiss() }
        } message: {
            Text("This reminder was saved, but it will not notify you until notifications are enabled in Settings.")
        }
    }

    @ViewBuilder
    private func repeatControls(for frequency: ReminderRepeatFrequency) -> some View {
        switch frequency {
        case .weekly:
            Picker("Day", selection: $repeatWeekday) {
                ForEach(Array(Calendar.current.weekdaySymbols.enumerated()), id: \.offset) { index, name in
                    Text(name).tag(index + 1)
                }
            }
            .accessibilityIdentifier("reminder.repeatWeekday")
        case .monthly:
            Picker("Day of month", selection: $repeatDayOfMonth) {
                ForEach(1...31, id: \.self) { day in Text("\(day)").tag(day) }
            }
            .accessibilityIdentifier("reminder.repeatDayOfMonth")
            Text("Dates that do not exist in a month use its last day.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .yearly:
            Picker("Month", selection: $repeatMonth) {
                ForEach(Array(Calendar.current.monthSymbols.enumerated()), id: \.offset) { index, name in
                    Text(name).tag(index + 1)
                }
            }
            .accessibilityIdentifier("reminder.repeatMonth")
            Text("Uses day \(repeatDayOfMonth) from the due date; shorter months use their last day.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func toggleTag(_ normalizedName: String) {
        if selectedTagNames.contains(normalizedName) {
            selectedTagNames.remove(normalizedName)
        } else {
            selectedTagNames.insert(normalizedName)
        }
    }

    private func addTag() {
        if let error = ReminderTag.validationError(for: newTagName) {
            tagValidationMessage = error
            return
        }

        let displayName = ReminderTag.displayName(from: newTagName)
        let normalizedName = ReminderTag.normalizedName(from: displayName)
        selectedTagNames.insert(normalizedName)

        if !availableTags.contains(where: { $0.normalizedName == normalizedName }) {
            pendingTagNames[normalizedName] = displayName
        }

        newTagName = ""
        tagValidationMessage = nil
    }

    private func importPhoto(_ item: PhotosPickerItem) {
        Task {
            defer { selectedPhoto = nil }
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                attachmentMessage = ReminderAttachmentStoreError.importFailed.localizedDescription
                return
            }
            let contentType = item.supportedContentTypes.first?.identifier ?? UTType.image.identifier
            stage(data: data, kind: .photo, displayName: "Photo", contentTypeIdentifier: contentType)
        }
    }

    private func importFile(_ url: URL) {
        let contentType = UTType(filenameExtension: url.pathExtension)?.identifier ?? UTType.data.identifier
        do {
            let draft = try attachmentStore.stage(
                fileAt: url,
                displayName: url.lastPathComponent,
                contentTypeIdentifier: contentType,
                existingCount: attachmentCount,
                existingByteCount: attachmentByteCount
            )
            draftAttachments.append(draft)
            attachmentMessage = nil
        } catch {
            attachmentMessage = error.localizedDescription
        }
    }

    private func stage(data: Data, kind: ReminderAttachmentKind, displayName: String, contentTypeIdentifier: String) {
        do {
            let draft = try attachmentStore.stage(
                data: data,
                kind: kind,
                displayName: displayName,
                contentTypeIdentifier: contentTypeIdentifier,
                existingCount: attachmentCount,
                existingByteCount: attachmentByteCount
            )
            draftAttachments.append(draft)
            attachmentMessage = nil
        } catch {
            attachmentMessage = error.localizedDescription
        }
    }

    private func removeDraftAttachment(_ attachment: ReminderAttachmentDraft) {
        attachmentStore.discard([attachment])
        draftAttachments.removeAll { $0.id == attachment.id }
    }

    private func cancel() {
        attachmentStore.discard(draftAttachments)
        dismiss()
    }

    private func save() {
        if let validationError = draft.validationError(allowingPastDueAt: originalDueAt) {
            validationMessage = validationError
            return
        }

        let resolvedTags = selectedTagNames.compactMap { normalizedName -> ReminderTag? in
            if let existingTag = availableTags.first(where: { $0.normalizedName == normalizedName }) {
                return existingTag
            }

            guard let displayName = pendingTagNames[normalizedName] else { return nil }
            let tag = ReminderTag(name: displayName)
            modelContext.insert(tag)
            return tag
        }

        let recurrenceService = RecurringReminderService()
        let savedReminder: Reminder
        let updatedFutureOccurrence: Reminder?
        if let reminder {
            if reminder.isRecurringOccurrence {
                updatedFutureOccurrence = recurrenceService.applyEdit(
                    to: reminder,
                    draft: draft,
                    tags: resolvedTags,
                    scope: recurringEditScope
                )
            } else if draft.repeatRule != nil {
                recurrenceService.startRecurrence(for: reminder, draft: draft, tags: resolvedTags, in: modelContext)
                updatedFutureOccurrence = nil
            } else {
                reminder.update(from: draft, tags: resolvedTags)
                updatedFutureOccurrence = nil
            }
            savedReminder = reminder
        } else if draft.repeatRule != nil {
            savedReminder = recurrenceService.createRecurringReminder(from: draft, tags: resolvedTags, in: modelContext)
            updatedFutureOccurrence = nil
        } else {
            let newReminder = Reminder(draft: draft)
            newReminder.tags = resolvedTags
            modelContext.insert(newReminder)
            savedReminder = newReminder
            updatedFutureOccurrence = nil
        }

        do {
            try applyAttachmentChanges(to: savedReminder)
        } catch {
            attachmentMessage = error.localizedDescription
            return
        }

        let shouldPromptForPermission = ReminderNotificationPolicy.shouldSchedule(savedReminder) && !hasPromptedForNotifications
        if shouldPromptForPermission {
            hasPromptedForNotifications = true
        }

        Task {
            var shouldShowGuidance = false
            var reconciledReminderIDs = Set<UUID>()
            for reminder in [savedReminder, updatedFutureOccurrence].compactMap({ $0 })
                where reconciledReminderIDs.insert(reminder.id).inserted {
                shouldShowGuidance = await notificationService.reconcile(
                    reminder,
                    requestAuthorizationIfNeeded: shouldPromptForPermission
                ) || shouldShowGuidance
            }
            if shouldShowGuidance {
                isShowingNotificationGuidance = true
            } else {
                dismiss()
            }
        }
    }

    private func applyAttachmentChanges(to reminder: Reminder) throws {
        for attachment in attachmentsMarkedForRemoval {
            attachmentStore.removePayload(for: attachment)
            modelContext.delete(attachment)
        }

        _ = try attachmentStore.commit(draftAttachments, attachingTo: reminder, in: modelContext)
        draftAttachments = []
    }
}

private struct AttachmentEditorRow: View {
    let title: String
    let subtitle: String
    let kind: ReminderAttachmentKind
    let thumbnailURL: URL?
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AttachmentThumbnailView(payloadURL: thumbnailURL, kind: kind)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).lineLimit(1)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Remove", role: .destructive, action: remove)
                .accessibilityLabel("Remove \(title)")
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TagOption: Identifiable {
    let id: String
    let name: String
}

#Preview {
    NavigationStack {
        ReminderEditorView()
    }
    .modelContainer(for: [Reminder.self, ReminderTag.self, ReminderSeries.self, ReminderAttachment.self], inMemory: true)
    .environmentObject(ReminderNotificationService())
}
