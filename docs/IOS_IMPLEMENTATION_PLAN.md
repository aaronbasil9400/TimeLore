# TimeLore iOS Implementation Plan

## Outcome

Produce a reliable, local-first reminders app in Xcode before investing in TimeLore’s OCR, location, cloud, or AI vision. The MVP includes the core reminder loop, recurring reminders, and basic reminder-scoped photo, file, and contact-card attachments. Each milestone is a vertical slice that can be demonstrated on a simulator or device.

**Overall MVP status: In progress.** Milestones 0–2 are complete. Notification reliability and final polish are under acceptance review. Recurrence is the next implementation slice, followed by local attachments and the integrated MVP trial.

## Project Bootstrap

Create the project in Xcode with these settings:

- Product name: `TimeLore`
- Interface: SwiftUI
- Language: Swift
- Persistence: SwiftData
- Tests: unit tests and UI tests
- Deployment target: iOS 17 or later (required by SwiftData)
- Bundle identifier: choose an identifier owned by the developer account
- Source control: use this existing repository; do not initialize a nested repository

Commit the shared scheme. Keep signing team settings user-local where Xcode permits. Do not enable CloudKit or other capabilities for the MVP.

Full Xcode is installed, while the active `xcode-select` path points to Command Line Tools. Use Xcode’s absolute `xcodebuild` path or select the full Xcode developer directory before command-line builds.

## Milestone 0 — Walking Skeleton

Deliver a launchable app with a SwiftData container and placeholder reminder list.

Acceptance criteria:

- App launches without network access.
- Shared scheme builds for an installed iOS Simulator.
- Unit and UI test targets run.
- A temporary in-memory model container is available to previews and tests.

**Status: Complete.** Project, shared scheme, SwiftData container, and in-memory previews are implemented. App and tests build, and the suite runs on the installed iPhone 17 simulator.

## Milestone 1 — Capture and Persist

Implement the reminder model, open-reminders list, and create form.

Acceptance criteria:

- A user can save a title, optional Notes, and optional future due date.
- Blank or whitespace-only titles cannot be saved.
- A saved reminder survives app termination and relaunch.
- The list has a useful empty state and deterministic ordering.
- Unit tests cover validation and ordering.

**Status: Complete.** Capture, validation, deterministic ordering, persistence, and simulator coverage are implemented and verified.

## Milestone 2 — Inspect and Maintain

Add detail, edit, complete, reopen, archive, restore, delete, and tag-organization flows.

Acceptance criteria:

- Edits persist and update `updatedAt`.
- Completion records `completedAt`; reopening clears it.
- Completed reminders appear separately and are not lost.
- Open, Completed, and Archived sections collapse independently and remember the user’s choices.
- Archiving preserves completion status; restoring returns a reminder to the correct section.
- Reminders support multiple normalized tags and tag filtering.
- Priority and Important remain independent across lifecycle transitions.
- Delete requires confirmation.
- Unit and UI tests cover status transitions and maintenance flows.

**Status: Complete.** Maintenance, Priority, Important, tag, sorting, and directional-swipe behavior are implemented and covered by domain and UI tests on an iPhone 17 simulator.

## Milestone 3 — Notify Reliably

Add a notification service around `UNUserNotificationCenter`.

Acceptance criteria:

- Permission is requested in context when the first dated reminder is saved, not at launch.
- Saving or changing a future due date schedules exactly one notification for that reminder.
- Completing, deleting, removing the date, or moving it into the past cancels pending notification work.
- Denied permission does not block saving and produces clear UI guidance.
- Unit tests use a fake notification client and verify scheduling decisions.

**Status: In progress.** The notification protocol, policy, reconciliation service, and focused tests are implemented. Manual device delivery, denied-permission guidance, and final lifecycle acceptance checks remain.

## Milestone 4 — Find and Polish

Add local search and complete accessibility and resilience passes.

Acceptance criteria:

- Search is case-insensitive across title and Notes.
- Empty search restores the normal list.
- Dynamic Type does not clip essential controls at accessibility sizes.
- VoiceOver labels distinguish reminder title, due state, and completion actions.
- UI tests cover create → relaunch → edit → complete and notification-denied behavior where practical.

**Status: In progress.** Local search, core accessibility labels, pure-white/OLED-black content layers, and primary UI paths are implemented. Dynamic Type, VoiceOver, locale, Reduced Transparency, and founder-device review remain part of the final acceptance audit.

## Milestone 5 — Recurring Reminders

Add explicit repeat rules, recurring occurrence history, and deterministic notification reconciliation.

Acceptance criteria:

- Repeat is off by default and requires a due date and time.
- The editor and detail views show a human-readable repeat summary.
- Completing one occurrence retains its completed history and advances or creates exactly one next occurrence.
- Editing or stopping recurrence never deletes completed occurrence history.
- Editing or deleting a recurring reminder explicitly communicates whether the change affects one occurrence or the remaining series whenever that distinction exists.
- Archive, restore, completion, reopening, deletion, app relaunch, timezone changes, and notification reconciliation do not create duplicate occurrences or pending requests.
- Recurrence date calculations use calendar/timezone semantics and have focused tests for daylight-saving and end-of-month boundaries.

**Status: In progress.** The recurrence domain, native editor/detail controls, notification identifiers, and focused automated coverage are implemented. Device acceptance of notification delivery and timezone behavior remains.

MVP decisions:

- Repeats are custom weekly, monthly, or yearly schedules only; there are no arbitrary intervals or end conditions.
- Weekly chooses one weekday. Monthly chooses day 1–31. Yearly chooses a month and retains the due-date day.
- A requested day unavailable in a shorter month uses that month’s final day. The selected local time is retained.
- Editing a recurring reminder always prompts for This occurrence or This and future occurrences. Deletion uses the same explicit scope wording.

## Milestone 6 — Reminder Attachments

Add local, reminder-scoped photo, file, and contact-card attachments without introducing OCR, sync, or a people graph.

Acceptance criteria:

- New and Edit Reminder offer explicit Add Photo, Add File, and Add Contact Card actions using Apple system pickers.
- Selected payloads are copied into app-owned local storage before temporary picker access expires.
- Contact cards are stored as user-selected local vCard snapshots; the app does not request broad Contacts access or maintain live contact syncing.
- Draft and saved attachments show type, accessible display name, thumbnail or icon, import state, and remove action.
- Saved attachments persist across app termination/relaunch and open through an appropriate local preview.
- Picker cancellation or permission denial leaves the draft intact and saving available.
- Missing, unsupported, oversized, or corrupt payloads show a recoverable error without blocking the reminder.
- Removing an attachment or deleting its reminder cleans up only the associated app-owned payload.
- Attachment lifecycle and cleanup have focused persistence/service tests; add/preview/remove have UI coverage.

**Status: In progress.** Local metadata/payload storage, system pickers, preview, removal, cleanup, and focused automated coverage are implemented. System picker and on-device preview acceptance remain.

MVP decisions:

- A reminder accepts up to six attachments with a combined 15 MB limit. Any single item that would exceed that total is rejected.
- Photos come from the system photo picker; files come from the system Files picker and preview through Quick Look when the system supports the type; contact cards are stored as local vCard snapshots. The MVP does not export or share attachments.
- Recurring reminder attachments belong to the series and are available to every occurrence.

## Milestone 7 — Integrated Acceptance and Small User Trial

Install on founder devices, then distribute a narrow beta only after the previous milestones pass.

Tasks:

- Test daylight-saving changes, locale changes, app termination, and notification permission changes.
- Test recurrence generation, edits, stopping, archive/restore, and notification delivery across timezone and daylight-saving boundaries.
- Test attachment import, relaunch persistence, offline preview, removal, cleanup, storage pressure, and picker cancellation.
- Run a two-week trial with 5–10 target users.
- Ask when Notes or attachments were useful, when capture felt slow, and whether recurring reminders behaved predictably.
- Record evidence and choose exactly one next experiment.

**Status: Pending Milestones 3–6.**

## Suggested Domain Shape

Use a small SwiftData model. Exact annotations and relationships should be decided in code, but the domain should remain equivalent to:

```swift
enum ReminderStatus: String, Codable {
    case open
    case completed
}

struct ReminderDraft {
    var title: String
    var reason: String
    var dueAt: Date?
    var repeatRule: RepeatRule?
    var attachments: [ReminderAttachmentDraft]
}

// Persisted Reminder fields:
// id, title, reason, dueAt, repeatRule, recurrence identity,
// priority, isImportant, status, tags, attachment metadata,
// createdAt, updatedAt, completedAt, archivedAt
```

One-time reminders may continue to use the reminder UUID string as the local-notification request identifier. Recurring occurrences need a deterministic series/occurrence identifier so reconciliation can update or cancel exactly one pending request without colliding with completed history.

Store attachment metadata in SwiftData and payloads in an app-owned Application Support directory. Persist stable relative identifiers, not temporary picker URLs or device-specific absolute paths.

## Test Strategy

- **Unit tests:** validation, sort order, status transitions, recurrence calculations, occurrence generation, and notification policy.
- **Persistence tests:** CRUD against an in-memory SwiftData container plus attachment metadata/payload lifecycle and cleanup.
- **UI tests:** critical reminder, recurrence, and attachment paths plus key empty, cancellation, and permission states.
- **Manual device tests:** notification delivery, permission settings, background/terminated behavior, Photos/Files/Contacts pickers, local previews, and accessibility.

## Decision Gates

After the expanded MVP trial, select one path:

1. Improve the core capture loop if speed or clarity is weak.
2. Add the most-requested post-MVP context or intelligence capability if Notes and attachments prove valuable.
3. Stop or reposition if users do not value context enough to change behavior.

Cloud sync, OCR, relationship graphs, and AI are architectural commitments, not default next steps.
