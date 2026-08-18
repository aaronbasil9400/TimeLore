import SwiftData
import SwiftUI

struct ReminderEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var reason = ""
    @State private var includesDueDate = false
    @State private var dueAt = Date.now.addingTimeInterval(60 * 60)
    @State private var validationMessage: String?

    private var draft: ReminderDraft {
        ReminderDraft(title: title, reason: reason, dueAt: includesDueDate ? dueAt : nil)
    }

    var body: some View {
        Form {
            Section("Reminder") {
                TextField("What do you need to do?", text: $title, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(1...3)
                    .accessibilityLabel("Reminder title")

                TextField("Why does this matter?", text: $reason, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(3...8)
                    .accessibilityLabel("Reminder context")
            }

            Section("When") {
                Toggle("Set a due date", isOn: $includesDueDate.animation())

                if includesDueDate {
                    DatePicker(
                        "Due",
                        selection: $dueAt,
                        in: Date.now...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
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
        .navigationTitle("New reminder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .accessibilityHint("Saves this reminder locally")
            }
        }
    }

    private func save() {
        if let validationError = draft.validationError() {
            validationMessage = validationError
            return
        }

        modelContext.insert(Reminder(draft: draft))
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ReminderEditorView()
    }
    .modelContainer(for: Reminder.self, inMemory: true)
}
