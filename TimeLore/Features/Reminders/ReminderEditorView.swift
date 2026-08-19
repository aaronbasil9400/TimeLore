import SwiftData
import SwiftUI

struct ReminderEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderTag.name) private var availableTags: [ReminderTag]

    private let reminder: Reminder?
    private let originalDueAt: Date?

    @State private var title: String
    @State private var reason: String
    @State private var includesDueDate: Bool
    @State private var dueAt: Date
    @State private var selectedTagNames: Set<String>
    @State private var pendingTagNames: [String: String] = [:]
    @State private var newTagName = ""
    @State private var validationMessage: String?
    @State private var tagValidationMessage: String?

    init(reminder: Reminder? = nil) {
        self.reminder = reminder
        originalDueAt = reminder?.dueAt
        _title = State(initialValue: reminder?.title ?? "")
        _reason = State(initialValue: reminder?.reason ?? "")
        _includesDueDate = State(initialValue: reminder?.dueAt != nil)
        _dueAt = State(initialValue: reminder?.dueAt ?? Date.now.addingTimeInterval(60 * 60))
        _selectedTagNames = State(initialValue: Set(reminder?.tags.map(\.normalizedName) ?? []))
    }

    private var draft: ReminderDraft {
        ReminderDraft(title: title, reason: reason, dueAt: includesDueDate ? dueAt : nil)
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

                TextField("Why does this matter?", text: $reason, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(3...8)
                    .accessibilityLabel("Reminder context")
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
                }
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
                Button("Cancel") { dismiss() }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .accessibilityHint("Saves this reminder locally")
                    .accessibilityIdentifier("reminder.save")
            }
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

        if let reminder {
            reminder.update(from: draft, tags: resolvedTags)
        } else {
            let newReminder = Reminder(draft: draft)
            newReminder.tags = resolvedTags
            modelContext.insert(newReminder)
        }

        dismiss()
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
    .modelContainer(for: [Reminder.self, ReminderTag.self], inMemory: true)
}
