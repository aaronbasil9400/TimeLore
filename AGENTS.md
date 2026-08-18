# Breadcrumb Repository Guide

## Mission

Build Breadcrumb as an iOS reminder app that preserves the reason behind a reminder. Prove the capture → notify → complete loop before adding the broader memory-assistant vision.

## Read First

For product or engineering work, read these files in order:

1. `README.md`
2. `docs/MVP_PRODUCT_BRIEF.md`
3. `docs/IOS_IMPLEMENTATION_PLAN.md`

The existing founder documents are vision inputs, not an implementation backlog. If they conflict with the MVP brief, the MVP brief controls current work.

## Current Scope

The first build is local-only and supports:

- Create, view, edit, complete, reopen, and delete reminders.
- Store a title, optional “why,” optional due date, status, and timestamps.
- Schedule or cancel a local notification for reminders with a due date.
- Show open and completed reminders.
- Search title and “why” text locally.

Do not add accounts, CloudKit, collaboration, OCR, receipts, automatic location capture, voice transcription, AI, subscriptions, analytics SDKs, or a generalized memory graph unless the active task explicitly changes scope.

## Engineering Defaults

- Use SwiftUI for UI and SwiftData for persistence.
- Use `NavigationStack` and small feature-oriented views.
- Keep business rules outside views in testable types. Do not introduce MVVM objects that only relay stored properties.
- Wrap notification authorization and scheduling behind a protocol so tests do not invoke system services.
- Store dates as `Date`; format them only at the UI boundary.
- Model reminder status explicitly rather than inferring it from dates.
- Prefer Apple frameworks and zero third-party dependencies for the MVP.
- Keep the app functional offline and collect no data by default.

## Proposed Source Layout

```text
Breadcrumb/
├── App/
├── Features/
│   └── Reminders/
├── Models/
├── Services/
├── Shared/
└── Resources/
BreadcrumbTests/
BreadcrumbUITests/
```

Use this layout after the Xcode project is created; do not create empty folders merely to match it.

## Change Workflow

1. Identify the next unchecked milestone in `docs/IOS_IMPLEMENTATION_PLAN.md`.
2. Implement the smallest end-to-end slice that produces user-visible value.
3. Add or update tests for domain rules and service behavior.
4. Build and test using the repository’s shared Xcode scheme.
5. Update documentation only when scope, architecture, or setup changed.

Use the repo skill at `.agents/skills/breadcrumb-ios-development/SKILL.md` for implementation and review tasks.

## Validation

Once an Xcode project exists, prefer commands equivalent to:

```bash
xcodebuild -scheme Breadcrumb -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme Breadcrumb -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Discover available simulators first and substitute an installed device. Do not claim a build or test passed unless the command was run successfully. If full Xcode is unavailable, state that limitation and still run any checks that are available.

## Definition of Done for a Slice

- The acceptance criteria in the implementation plan are met.
- Empty, error, permission-denied, and relevant edge states are handled.
- Accessibility labels and Dynamic Type remain usable.
- New business logic has focused tests.
- No deferred feature is pulled into the change accidentally.
- The working tree contains no unrelated generated artifacts or secrets.

