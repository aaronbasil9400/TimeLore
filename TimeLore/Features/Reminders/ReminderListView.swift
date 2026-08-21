import SwiftData
import SwiftUI

struct ReminderListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var notificationService: ReminderNotificationService
    @Environment(\.modelContext) private var modelContext
    @Query private var reminders: [Reminder]
    @Query(sort: \ReminderTag.name) private var tags: [ReminderTag]

    @ScaledMetric(relativeTo: .largeTitle) private var expandedLogoWidth = 148
    @ScaledMetric(relativeTo: .headline) private var compactLogoWidth = 92

    @AppStorage("reminderSections.open.expanded") private var isOpenExpanded = true
    @AppStorage("reminderSections.completed.expanded") private var isCompletedExpanded = false
    @AppStorage("reminderSections.archived.expanded") private var isArchivedExpanded = false

    @State private var isPresentingNewReminder = false
    @State private var isPresentingTagManagement = false
    @State private var isBrandHeaderCompact = false
    @State private var searchText = ""
    @State private var tagFilter: TagFilter = .all
    @AppStorage("reminderSortMode") private var sortModeRawValue = ReminderSortMode.dueDate.rawValue

    private var filteredReminders: [Reminder] {
        reminders.filter(matchesSearch).filter(matchesTagFilter)
    }

    private var openReminders: [Reminder] {
        let reminders = filteredReminders.filter { $0.archivedAt == nil && $0.status == .open }
        return reminders.sorted(by: sortMode == .priority ? Reminder.prioritySortOrder : Reminder.openSortOrder)
    }

    private var completedReminders: [Reminder] {
        filteredReminders.filter { $0.archivedAt == nil && $0.status == .completed }.sorted(by: Reminder.completedSortOrder)
    }

    private var archivedReminders: [Reminder] {
        filteredReminders.filter { $0.archivedAt != nil }.sorted(by: Reminder.archivedSortOrder)
    }

    private var orderedTags: [ReminderTag] {
        tags.sorted {
            let left = defaultTagRank(for: $0)
            let right = defaultTagRank(for: $1)
            return left == right
                ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                : left < right
        }
    }

    private func defaultTagRank(for tag: ReminderTag) -> Int {
        DefaultReminderTagSeeder.rank(for: tag)
    }

    private var sortMode: ReminderSortMode {
        ReminderSortMode(rawValue: sortModeRawValue) ?? .dueDate
    }

    var body: some View {
        NavigationStack {
            List {
                brandHeader
                tagFilterRow

                if reminders.isEmpty {
                    ContentUnavailableView {
                        Label("Remember what, and why.", systemImage: "lightbulb")
                    } description: {
                        Text("Capture a reminder with the context you will need later.")
                    } actions: {
                        Button("New reminder") { isPresentingNewReminder = true }
                    }
                    .listRowBackground(Color.clear)
                } else if filteredReminders.isEmpty {
                    ContentUnavailableView {
                        Label("No reminders found", systemImage: "magnifyingglass")
                    } description: {
                        Text("Your search or selected filter removed all results.")
                    } actions: {
                        Button("Clear filters", action: clearFilters)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ReminderDisclosureSection(identifier: "section.open", title: "Open", count: openReminders.count, isExpanded: $isOpenExpanded) {
                        reminderRows(openReminders, emptyMessage: "No open reminders")
                    }
                    ReminderDisclosureSection(identifier: "section.completed", title: "Completed", count: completedReminders.count, isExpanded: $isCompletedExpanded) {
                        reminderRows(completedReminders, emptyMessage: "No completed reminders")
                    }
                    ReminderDisclosureSection(identifier: "section.archived", title: "Archived", count: archivedReminders.count, isExpanded: $isArchivedExpanded) {
                        reminderRows(archivedReminders, emptyMessage: "No archived reminders")
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .modifier(BrandScrollTrackingModifier(isCompact: $isBrandHeaderCompact))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search reminders")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if isBrandHeaderCompact {
                        TimeLoreBrandLogo(
                            width: min(compactLogoWidth, 116),
                            accessibilityIdentifier: "brand.logo.compact"
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Section("Sort") {
                            Button {
                                sortModeRawValue = ReminderSortMode.dueDate.rawValue
                            } label: {
                                Label("Due date", systemImage: sortMode == .dueDate ? "checkmark" : "calendar")
                            }
                            Button {
                                sortModeRawValue = ReminderSortMode.priority.rawValue
                            } label: {
                                Label("Priority", systemImage: sortMode == .priority ? "checkmark" : "exclamationmark.3")
                            }
                        }

                        Button {
                            isPresentingTagManagement = true
                        } label: {
                            Label("Manage Tags", systemImage: "tag")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("More options")
                    .accessibilityValue("Sorted by \(sortMode.accessibilityName)")
                    .accessibilityIdentifier("reminder.moreActions")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("New reminder", systemImage: "plus") { isPresentingNewReminder = true }
                        .accessibilityHint("Creates a reminder with optional context, due date, tags, and Important state")
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: isBrandHeaderCompact)
            .sheet(isPresented: $isPresentingNewReminder) {
                NavigationStack { ReminderEditorView() }
            }
            .sheet(isPresented: $isPresentingTagManagement) {
                TagManagementView()
            }
            .onChange(of: tags.map(\.id)) { _, tagIDs in
                guard case let .tag(selectedTagID) = tagFilter,
                      !tagIDs.contains(selectedTagID) else { return }
                tagFilter = .all
            }
        }
        .task {
            for reminder in reminders {
                _ = await notificationService.reconcile(reminder, requestAuthorizationIfNeeded: false)
            }
        }
    }

    private var brandHeader: some View {
        HStack {
            TimeLoreBrandLogo(
                width: min(expandedLogoWidth, 196),
                accessibilityIdentifier: "brand.logo.expanded"
            )
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .listRowInsets(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .onAppear { isBrandHeaderCompact = false }
        .onDisappear { isBrandHeaderCompact = true }
    }

    private var tagFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterButton(title: "All", symbol: "tray.full", tint: .gray, filter: .all)
                filterButton(title: "Important", symbol: "flag.fill", tint: .orange, filter: .important)
                filterButton(title: "Untagged", symbol: "tag.slash", tint: .gray, filter: .untagged)
                ForEach(orderedTags) { tag in
                    filterButton(tag: tag)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 8, trailing: 0))
        .listRowSeparator(.hidden)
        .accessibilityLabel("Filter reminders")
    }

    private func filterButton(title: String, symbol: String? = nil, tint: Color? = nil, filter: TagFilter) -> some View {
        Button { tagFilter = filter } label: {
            ReminderTagChip(
                name: title,
                isSelected: tagFilter == filter,
                symbol: symbol,
                tint: tint,
                style: .filter
            )
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: tagFilter == filter)
        .accessibilityLabel("\(title) filter")
        .accessibilityValue(tagFilter == filter ? "Selected" : "Not selected")
    }

    private func filterButton(tag: ReminderTag) -> some View {
        let filter = TagFilter.tag(tag.id)
        return Button { tagFilter = filter } label: {
            ReminderTagChip(tag: tag, isSelected: tagFilter == filter, style: .filter)
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: tagFilter == filter)
        .accessibilityLabel("\(tag.name) filter")
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
                ReminderListItem(reminder: reminder) {
                    toggleCompletion(for: reminder)
                }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if reminder.archivedAt == nil { progressSwipeAction(for: reminder) }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        organizationSwipeActions(for: reminder)
                    }
                    .listRowInsets(EdgeInsets(top: 3, leading: 16, bottom: 3, trailing: 16))
                    .listRowSeparatorTint(Color.secondary.opacity(0.2))
                    .listRowBackground(Color.clear)
            }
        }
    }

    @ViewBuilder
    private func progressSwipeAction(for reminder: Reminder) -> some View {
        if reminder.status == .completed {
            Button("Reopen", systemImage: "arrow.uturn.backward") {
                toggleCompletion(for: reminder)
            }
            .tint(.blue)
        } else {
            Button("Complete", systemImage: "checkmark") {
                toggleCompletion(for: reminder)
            }
            .tint(.green)
        }
    }

    @ViewBuilder
    private func organizationSwipeActions(for reminder: Reminder) -> some View {
        Button(reminder.archivedAt == nil ? "Archive" : "Restore", systemImage: reminder.archivedAt == nil ? "archivebox" : "arrow.uturn.backward") {
            if reminder.archivedAt == nil { reminder.archive() } else { reminder.restore() }
        }
        .tint(reminder.archivedAt == nil ? .orange : .blue)

        Button(reminder.isImportant ? "Unflag" : "Flag", systemImage: reminder.isImportant ? "flag.slash" : "flag") {
            reminder.setImportant(!reminder.isImportant)
        }
        .tint(.orange)
    }

    private func matchesSearch(_ reminder: Reminder) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return reminder.title.localizedCaseInsensitiveContains(query) || reminder.reason.localizedCaseInsensitiveContains(query)
    }

    private func matchesTagFilter(_ reminder: Reminder) -> Bool {
        switch tagFilter {
        case .all: true
        case .important: reminder.isImportant
        case .untagged: reminder.tags.isEmpty
        case let .tag(tagID): reminder.tags.contains { $0.id == tagID }
        }
    }

    private func clearFilters() {
        searchText = ""
        tagFilter = .all
    }

    private func reconcileNotification(for reminder: Reminder) {
        Task { _ = await notificationService.reconcile(reminder, requestAuthorizationIfNeeded: false) }
    }

    private func toggleCompletion(for reminder: Reminder) {
        let recurrenceService = RecurringReminderService()
        if reminder.status == .completed {
            let removedSuccessor = recurrenceService.reopen(reminder, in: modelContext)
            if let removedSuccessor {
                Task { await notificationService.cancel(for: removedSuccessor) }
            }
        } else {
            let next = recurrenceService.complete(reminder, in: modelContext)
            if let next { reconcileNotification(for: next) }
        }
        reconcileNotification(for: reminder)
    }
}

private struct BrandScrollTrackingModifier: ViewModifier {
    @Binding var isCompact: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y > 40
            } action: { _, newValue in
                isCompact = newValue
            }
        } else {
            content
        }
    }
}

private enum TagFilter: Equatable {
    case all
    case important
    case untagged
    case tag(UUID)
}

private enum ReminderSortMode: String {
    case dueDate
    case priority

    var accessibilityName: String {
        self == .dueDate ? "Due date" : "Priority"
    }
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
                    .font(.headline.weight(.semibold))
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
        .tint(.secondary)
        .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18))
        .listRowBackground(Color.clear)
        .accessibilityIdentifier(identifier)
    }
}

private struct ReminderListItem: View {
    let reminder: Reminder
    let completionAction: () -> Void

    private var statusTint: Color {
        if reminder.status == .completed { return .green }
        if reminder.isImportant { return .orange }
        if let firstTag = reminder.tags.sorted(by: { $0.name < $1.name }).first {
            return ReminderTagPresentation.forTag(firstTag).color
        }
        return .blue
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if reminder.archivedAt == nil {
                Button(action: completionAction) {
                    Image(systemName: reminder.status == .completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(statusTint)
                        .font(.title2.weight(.medium))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(reminder.status == .completed ? "Reopen \(reminder.title)" : "Mark \(reminder.title) as completed")
                .accessibilityHint("Changes this reminder's completion state")
                .accessibilityIdentifier("reminder.completionControl")
            } else {
                Image(systemName: reminder.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(statusTint)
                    .font(.title2.weight(.medium))
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }

            NavigationLink { ReminderDetailView(reminder: reminder) } label: {
                ReminderRowContent(reminder: reminder)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(ReminderRowContent(reminder: reminder).accessibilitySummary)
            .accessibilityHint("Double tap to open. Swipe right to \(reminder.status == .completed ? "reopen" : "complete"). Swipe left for flag and archive actions.")
            .accessibilityIdentifier("reminder.row.\(reminder.id.uuidString)")
        }
        .padding(.vertical, 5)
    }
}

private struct ReminderRowContent: View {
    let reminder: Reminder

    private var sortedTags: [ReminderTag] {
        reminder.tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var isOverdue: Bool {
        reminder.status == .open && (reminder.dueAt ?? .distantFuture) < .now
    }

    var accessibilitySummary: String {
        var parts = [reminder.status == .completed ? "Completed" : "Open", reminder.title]
        if reminder.isImportant { parts.append("Important") }
        if reminder.priority != .none { parts.append(reminder.priority.accessibilityName) }
        if !reminder.reason.isEmpty { parts.append(reminder.reason) }
        if let dueAt = reminder.dueAt {
            parts.append(isOverdue ? "Overdue" : "Due")
            parts.append(dueAt.formatted(date: .abbreviated, time: .shortened))
        }
        if let rule = reminder.recurrenceSeries?.repeatRule, reminder.recurrenceSeries?.isStopped == false {
            parts.append(rule.summary())
        }
        if !reminder.visibleAttachments.isEmpty {
            parts.append("\(reminder.visibleAttachments.count) attachments")
        }
        if !sortedTags.isEmpty { parts.append("Tags: \(sortedTags.map(\.name).joined(separator: ", "))") }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if reminder.isImportant {
                    Image(systemName: "flag.fill").foregroundStyle(.orange).accessibilityHidden(true)
                }
                if reminder.priority != .none {
                    Text(reminder.priority.marker)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.red)
                        .accessibilityHidden(true)
                }
                Text(reminder.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
            }
            if !reminder.reason.isEmpty {
                Text(reminder.reason).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
            }
            if let dueAt = reminder.dueAt {
                Label { Text(dueAt, format: .dateTime.month(.abbreviated).day().hour().minute()) } icon: { Image(systemName: "calendar") }
                    .font(.caption)
                    .foregroundStyle(isOverdue ? .red : .secondary)
            }
            if reminder.recurrenceSeries?.isStopped == false || !reminder.visibleAttachments.isEmpty {
                HStack(spacing: 10) {
                    if reminder.recurrenceSeries?.isStopped == false {
                        Label("Repeats", systemImage: "arrow.triangle.2.circlepath")
                    }
                    if !reminder.visibleAttachments.isEmpty {
                        Label("\(reminder.visibleAttachments.count)", systemImage: "paperclip")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            }
            if !sortedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(sortedTags.prefix(3)) { tag in ReminderTagChip(tag: tag) }
                        if sortedTags.count > 3 {
                            Text("+\(sortedTags.count - 3)").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

private struct TimeLoreBrandLogo: View {
    let width: CGFloat
    let accessibilityIdentifier: String

    var body: some View {
        Image("TimeLoreLogo")
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .accessibilityLabel(AppIdentity.displayName)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#Preview("Reminders") {
    ReminderListView()
        .environmentObject(ReminderNotificationService())
        .modelContainer(for: [Reminder.self, ReminderTag.self, ReminderSeries.self, ReminderAttachment.self], inMemory: true)
}
