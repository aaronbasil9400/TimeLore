import SwiftData
import SwiftUI

struct TagManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \ReminderTag.name) private var tags: [ReminderTag]

    @State private var editorRequest: TagEditorRequest?
    @State private var alert: TagManagementAlert?

    private let manager = ReminderTagManager()

    private var orderedTags: [ReminderTag] {
        tags.sorted {
            let leftRank = DefaultReminderTagSeeder.rank(for: $0)
            let rightRank = DefaultReminderTagSeeder.rank(for: $1)
            return leftRank == rightRank
                ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                : leftRank < rightRank
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if orderedTags.isEmpty {
                    ContentUnavailableView {
                        Label("No tags", systemImage: "tag")
                    } description: {
                        Text("Create a tag to organize related reminders.")
                    } actions: {
                        Button("New tag") { presentNewTag() }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(orderedTags) { tag in
                            tagRow(tag)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        requestDeletion(of: tag)
                                    }
                                }
                        }
                    } footer: {
                        Text("Deleting a tag removes it from reminders, never the reminders themselves.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .navigationTitle("Manage Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("New tag", systemImage: "plus") { presentNewTag() }
                        .accessibilityIdentifier("tag.manage.add")
                }
            }
            .sheet(item: $editorRequest) { request in
                NavigationStack {
                    TagEditorView(tag: request.tag)
                }
            }
            .alert(item: $alert) { alert in
                if let tag = alert.tag {
                    Alert(
                        title: Text("Delete “\(tag.name)”?"),
                        message: Text(deletionMessage(for: tag)),
                        primaryButton: .cancel(),
                        secondaryButton: .destructive(Text("Delete Tag")) {
                            delete(tag)
                        }
                    )
                } else {
                    Alert(
                        title: Text("Couldn’t update tags"),
                        message: Text(alert.message ?? "Try again."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }

    private func tagRow(_ tag: ReminderTag) -> some View {
        let presentation = ReminderTagPresentation.forTag(tag)
        return Button {
            editorRequest = TagEditorRequest(tag: tag)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: presentation.symbol)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(presentation.color)
                    .frame(width: 42, height: 42)
                    .background(presentation.color.opacity(colorScheme == .dark ? 0.24 : 0.12), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(tag.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(reminderCountDescription(for: tag))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit \(tag.name) tag")
        .accessibilityValue(reminderCountDescription(for: tag))
        .accessibilityHint("Opens name, color, and icon settings")
    }

    private func presentNewTag() {
        editorRequest = TagEditorRequest(tag: nil)
    }

    private func requestDeletion(of tag: ReminderTag) {
        if tag.reminders.isEmpty {
            delete(tag)
        } else {
            alert = TagManagementAlert(tag: tag)
        }
    }

    private func delete(_ tag: ReminderTag) {
        do {
            try manager.delete(tag, in: modelContext)
        } catch {
            alert = TagManagementAlert(message: error.localizedDescription)
        }
    }

    private func reminderCountDescription(for tag: ReminderTag) -> String {
        let count = tag.reminders.count
        return count == 1 ? "Used by 1 reminder" : "Used by \(count) reminders"
    }

    private func deletionMessage(for tag: ReminderTag) -> String {
        let count = tag.reminders.count
        let reminderText = count == 1 ? "1 reminder" : "\(count) reminders"
        return "This removes the tag from \(reminderText). The reminders will not be deleted."
    }
}

private struct TagEditorRequest: Identifiable {
    let id = UUID()
    let tag: ReminderTag?
}

private struct TagManagementAlert: Identifiable {
    let id = UUID()
    var tag: ReminderTag?
    var message: String?

    init(tag: ReminderTag) {
        self.tag = tag
    }

    init(message: String) {
        self.message = message
    }
}

private struct TagEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    let tag: ReminderTag?
    private let manager = ReminderTagManager()

    @State private var name: String
    @State private var colorToken: ReminderTagColorToken
    @State private var symbolName: String
    @State private var validationMessage: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

    init(tag: ReminderTag?) {
        self.tag = tag
        _name = State(initialValue: tag?.name ?? "")
        _colorToken = State(initialValue: tag?.colorToken ?? .blue)
        _symbolName = State(initialValue: tag?.resolvedSymbolName ?? "tag")
    }

    var body: some View {
        Form {
            Section("Preview") {
                HStack {
                    Spacer()
                    ReminderTagChip(
                        name: ReminderTag.displayName(from: name).isEmpty ? "Tag name" : name,
                        colorToken: colorToken,
                        symbol: symbolName,
                        style: .filter
                    )
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            Section("Name") {
                TextField("Tag name", text: $name)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .accessibilityIdentifier("tag.editor.name")

                if let validationMessage {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Color") {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ReminderTagColorToken.allCases, id: \.self) { option in
                        colorButton(option)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Icon") {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(TagSymbolOption.all, id: \.symbolName) { option in
                        symbolButton(option)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .scrollContentBackground(.hidden)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .navigationTitle(tag == nil ? "New Tag" : "Edit Tag")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(ReminderTag.displayName(from: name).isEmpty)
                    .accessibilityIdentifier("tag.editor.save")
            }
        }
    }

    private func colorButton(_ option: ReminderTagColorToken) -> some View {
        let color = ReminderTagPresentation.color(for: option)
        return Button {
            colorToken = option
        } label: {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 34, height: 34)
                if colorToken == option {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.accessibilityName)
        .accessibilityValue(colorToken == option ? "Selected" : "Not selected")
        .accessibilityIdentifier("tag.color.\(option.rawValue)")
    }

    private func symbolButton(_ option: TagSymbolOption) -> some View {
        let color = ReminderTagPresentation.color(for: colorToken)
        return Button {
            symbolName = option.symbolName
        } label: {
            Image(systemName: option.symbolName)
                .font(.body.weight(.semibold))
                .foregroundStyle(symbolName == option.symbolName ? Color.white : color)
                .frame(width: 44, height: 44)
                .background(
                    symbolName == option.symbolName ? color : color.opacity(colorScheme == .dark ? 0.22 : 0.11),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.name)
        .accessibilityValue(symbolName == option.symbolName ? "Selected" : "Not selected")
        .accessibilityIdentifier("tag.icon.\(option.symbolName)")
    }

    private func save() {
        do {
            if let tag {
                try manager.update(
                    tag,
                    name: name,
                    colorToken: colorToken,
                    symbolName: symbolName,
                    in: modelContext
                )
            } else {
                try manager.create(
                    name: name,
                    colorToken: colorToken,
                    symbolName: symbolName,
                    in: modelContext
                )
            }
            dismiss()
        } catch {
            validationMessage = error.localizedDescription
        }
    }
}

private struct TagSymbolOption {
    let name: String
    let symbolName: String

    static let all = [
        Self(name: "Tag", symbolName: "tag"),
        Self(name: "Work", symbolName: "briefcase"),
        Self(name: "Person", symbolName: "person"),
        Self(name: "Folder", symbolName: "folder"),
        Self(name: "Shopping", symbolName: "cart"),
        Self(name: "Health", symbolName: "heart"),
        Self(name: "Checklist", symbolName: "checklist"),
        Self(name: "Home", symbolName: "house"),
        Self(name: "Book", symbolName: "book.closed"),
        Self(name: "Study", symbolName: "graduationcap"),
        Self(name: "Food", symbolName: "fork.knife"),
        Self(name: "Travel", symbolName: "airplane"),
        Self(name: "Car", symbolName: "car"),
        Self(name: "Exercise", symbolName: "figure.run"),
        Self(name: "Medical", symbolName: "cross.case"),
        Self(name: "Pets", symbolName: "pawprint"),
        Self(name: "Gift", symbolName: "gift"),
        Self(name: "Money", symbolName: "banknote"),
        Self(name: "Tools", symbolName: "wrench.and.screwdriver"),
        Self(name: "Nature", symbolName: "leaf"),
        Self(name: "Favorite", symbolName: "star"),
        Self(name: "Music", symbolName: "music.note")
    ]
}

#Preview("Manage Tags") {
    TagManagementView()
        .modelContainer(for: [Reminder.self, ReminderTag.self, ReminderSeries.self, ReminderAttachment.self], inMemory: true)
}
