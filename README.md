# TimeLore

TimeLore is an iOS reminder app built around one differentiator: a reminder should preserve not only **what** to do, but **why** it matters.

The repository contains the TimeLore Xcode project, product documentation, and implementation guidance.

**MVP status: In progress.** The reminder foundation is implemented and under acceptance review. Recurring reminders and reminder-scoped attachments are the next approved MVP slices.

## Start Here

- [MVP product brief](docs/MVP_PRODUCT_BRIEF.md) — the first-product boundary.
- [iOS implementation plan](docs/IOS_IMPLEMENTATION_PLAN.md) — ordered vertical slices and acceptance criteria.
- [Agent guidance](AGENTS.md) — engineering rules for people and coding agents.
- [Original app concept](Documentation/Breadcrumb%20App%20Concept.md) — long-term vision, not current scope.

## First Release

The first release is a private, offline reminder app with:

- A title and optional Notes context.
- An optional due date and local notification.
- Optional recurrence for due reminders.
- Reminder-scoped photo, file, and contact-card attachments stored locally.
- Independent Priority and Important controls.
- Open and completed lists.
- Archiving and independently collapsible status sections.
- Multi-tag organization and filtering.
- Local text search.
- SwiftData persistence.

The aim is to validate whether preserving context makes reminders more useful. Reminder recurrence and basic local attachments are part of this MVP; OCR, receipt intelligence, locations, sync, and AI remain outside it.

## Prerequisites

- A Mac with the full Xcode application installed.
- An iOS Simulator supported by that Xcode installation.
- No third-party packages are planned for the MVP.

See the implementation plan for project-creation settings and the first build sequence.
