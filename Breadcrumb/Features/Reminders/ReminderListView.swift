import SwiftData
import SwiftUI

struct ReminderListView: View {
    @Query private var reminders: [Reminder]
    @Query(sort: \ReminderTag.name) private var tags: [ReminderTag]

    @AppStorage("reminderSections.open.expanded") private var isOpenExpanded = true
    @AppStorage("reminderSections.completed.expanded") private var isCompletedExpanded = false
    @AppStorage("reminderSections.archived.expanded") private var isArchivedExpanded = false

    @State private var isPresentingNewReminder = false
    @State private var tagFilter: TagFilter = .all

    private var filteredReminders: [Reminder] {
        reminders.filter(matchesTagFilter)
    }

    private var openReminders: [Reminder] {
        filteredReminders
            .filter { $0.archivedAt == nil && $0.status == .open }
            .sorted(by: Reminder.openSortOrder)
    }

    private var completedReminders: [Reminder] {
        filteredReminders
            .filter { $0.archivedAt == nil && $0.status == .completed }
            .sorted(by: Reminder.completedSortOrder)
    }

    private var archivedReminders: [Reminder] {
        filteredReminders
            .filter { $0.archivedAt != nil }
            .sorted(by: Reminder.archivedSortOrder)
    }

    var body: some View {
        NavigationStack {
            List {
                tagFilterRow

        ReminderDisclosureSection(
                    identifier: "section.open",
                    title: "Open",
                    count: openReminders.count,
                    isExpanded: $isOpenExpanded
                ) {
                    reminderRows(openReminders, emptyMessage: "No open reminders")
                }

                ReminderDisclosureSection(
                    identifier: "section.completed",
                    title: "Completed",
                    count: completedReminders.count,
                    isExpanded: $isCompletedExpanded
                ) {
                    reminderRows(completedReminders, emptyMessage: "No completed reminders")
                }

                ReminderDisclosureSection(
                    identifier: "section.archived",
                    title: "Archived",
                    count: archivedReminders.count,
                    isExpanded: $isArchivedExpanded
                ) {
                    reminderRows(archivedReminders, emptyMessage: "No archived reminders")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Breadcrumb")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New reminder", systemImage: "plus") {
                        isPresentingNewReminder = true
                    }
                    .accessibilityHint("Creates a reminder with optional context, due date, and tags")
                }
            }
            .sheet(isPresented: $isPresentingNewReminder) {
                NavigationStack {
                    ReminderEditorView()
                }
            }
        }
    }

    private var tagFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                tagFilterButton(title: "All", filter: .all)
                tagFilterButton(title: "Untagged", filter: .untagged)

                ForEach(tags) { tag in
                    tagFilterButton(title: tag.name, filter: .tag(tag.id))
                }
            }
            .padding(.vertical, 2)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        .accessibilityLabel("Filter reminders by tag")
    }

    private func tagFilterButton(title: String, filter: TagFilter) -> some View {
        Button {
            tagFilter = filter
        } label: {
            ReminderTagChip(name: title, isSelected: tagFilter == filter)
        }
        .buttonStyle(.plain)
        .accessibilityValue(tagFilter == filter ? "Selected" : "Not selected")
    }

    @ViewBuilder
    private func reminderRows(_ reminders: [Reminder], emptyMessage: String) -> some View {
        if reminders.isEmpty {
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("section.empty")
        } else {
            ForEach(reminders) { reminder in
                NavigationLink {
                    ReminderDetailView(reminder: reminder)
                } label: {
                    ReminderRow(reminder: reminder)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    primarySwipeAction(for: reminder)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if reminder.archivedAt == nil {
                        Button("Archive", systemImage: "archivebox") {
                            reminder.archive()
                        }
                        .tint(.orange)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func primarySwipeAction(for reminder: Reminder) -> some View {
        if reminder.archivedAt != nil {
            Button("Restore", systemImage: "arrow.uturn.backward") {
                reminder.restore()
            }
            .tint(.blue)
        } else if reminder.status == .completed {
            Button("Reopen", systemImage: "arrow.uturn.backward") {
                reminder.reopen()
            }
            .tint(.blue)
        } else {
            Button("Complete", systemImage: "checkmark") {
                reminder.complete()
            }
            .tint(.green)
        }
    }

    private func matchesTagFilter(_ reminder: Reminder) -> Bool {
        switch tagFilter {
        case .all:
            true
        case .untagged:
            reminder.tags.isEmpty
        case let .tag(id):
            reminder.tags.contains { $0.id == id }
        }
    }
}

private enum TagFilter: Equatable {
    case all
    case untagged
    case tag(UUID)
}

private struct ReminderDisclosureSection<Content: View>: View {
    let identifier: String
    let title: String
    let count: Int
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content()
        } label: {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(count, format: .number)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title), \(count) reminders")
            .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand")
        }
        .accessibilityIdentifier(identifier)
    }
}

private struct ReminderRow: View {
    let reminder: Reminder

    private var sortedTags: [ReminderTag] {
        reminder.tags.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

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

            if !sortedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(sortedTags) { tag in
                            ReminderTagChip(name: tag.name)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("reminder.row.\(reminder.id.uuidString)")
    }
}

#Preview("Reminders") {
    ReminderListView()
        .modelContainer(for: [Reminder.self, ReminderTag.self], inMemory: true)
}
