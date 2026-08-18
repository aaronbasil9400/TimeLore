# Breadcrumb iOS Implementation Plan

## Outcome

Produce a basic, reliable reminders app in Xcode before investing in Breadcrumb’s OCR, location, cloud, or AI vision. Each milestone is a vertical slice that can be demonstrated on a simulator or device.

## Project Bootstrap

Create the project in Xcode with these settings:

- Product name: `Breadcrumb`
- Interface: SwiftUI
- Language: Swift
- Persistence: SwiftData
- Tests: unit tests and UI tests
- Deployment target: iOS 17 or later (required by SwiftData)
- Bundle identifier: choose an identifier owned by the developer account
- Source control: use this existing repository; do not initialize a nested repository

Commit the shared scheme. Keep signing team settings user-local where Xcode permits. Do not enable CloudKit or other capabilities for the MVP.

The current environment has Swift command-line tools but does not expose the full `xcodebuild` tool, so initial project generation and simulator verification must happen on a Mac with full Xcode selected.

## Milestone 0 — Walking Skeleton

Deliver a launchable app with a SwiftData container and placeholder reminder list.

Acceptance criteria:

- App launches without network access.
- Shared scheme builds for an installed iOS Simulator.
- Unit and UI test targets run.
- A temporary in-memory model container is available to previews and tests.

## Milestone 1 — Capture and Persist

Implement the reminder model, open-reminders list, and create form.

Acceptance criteria:

- A user can save a title, optional “why,” and optional future due date.
- Blank or whitespace-only titles cannot be saved.
- A saved reminder survives app termination and relaunch.
- The list has a useful empty state and deterministic ordering.
- Unit tests cover validation and ordering.

## Milestone 2 — Inspect and Maintain

Add detail, edit, complete, reopen, and delete flows.

Acceptance criteria:

- Edits persist and update `updatedAt`.
- Completion records `completedAt`; reopening clears it.
- Completed reminders appear separately and are not lost.
- Delete requires confirmation.
- Unit tests cover status transitions.

## Milestone 3 — Notify Reliably

Add a notification service around `UNUserNotificationCenter`.

Acceptance criteria:

- Permission is requested in context when the first dated reminder is saved, not at launch.
- Saving or changing a future due date schedules exactly one notification for that reminder.
- Completing, deleting, removing the date, or moving it into the past cancels pending notification work.
- Denied permission does not block saving and produces clear UI guidance.
- Unit tests use a fake notification client and verify scheduling decisions.

## Milestone 4 — Find and Polish

Add local search and complete accessibility and resilience passes.

Acceptance criteria:

- Search is case-insensitive across title and “why.”
- Empty search restores the normal list.
- Dynamic Type does not clip essential controls at accessibility sizes.
- VoiceOver labels distinguish reminder title, due state, and completion actions.
- UI tests cover create → relaunch → edit → complete and notification-denied behavior where practical.

## Milestone 5 — Small User Trial

Install on founder devices, then distribute a narrow beta only after the previous milestones pass.

Tasks:

- Test daylight-saving changes, locale changes, app termination, and notification permission changes.
- Run a two-week trial with 5–10 target users.
- Ask when “why” was useful, when capture felt slow, and what they expected but could not do.
- Record evidence and choose exactly one next experiment.

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
}

// Persisted Reminder fields:
// id, title, reason, dueAt, status,
// createdAt, updatedAt, completedAt
```

Use the reminder UUID string as the notification request identifier so updates and cancellation are idempotent.

## Test Strategy

- **Unit tests:** validation, sort order, status transitions, and notification policy.
- **Persistence tests:** CRUD against an in-memory SwiftData container.
- **UI tests:** one critical happy path plus key empty and permission states.
- **Manual device tests:** notification delivery, permission settings, background/terminated behavior, and accessibility.

## Decision Gates

After the trial, select one path:

1. Improve the core capture loop if speed or clarity is weak.
2. Add the most-requested context type if “why” proves valuable.
3. Stop or reposition if users do not value context enough to change behavior.

Cloud sync and AI are architectural commitments, not default next steps.
