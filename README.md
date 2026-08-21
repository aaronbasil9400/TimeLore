# TimeLore

TimeLore is an iOS reminder app built around one differentiator: a reminder should preserve not only **what** to do, but **why** it matters.

The repository contains the TimeLore Xcode project, product documentation, and implementation guidance.

**MVP status: In acceptance review.** The local reminder foundation, custom recurrence, and reminder-scoped photo/file attachments are implemented. Integrated device acceptance for notifications, system pickers, previews, accessibility, and timezone behavior remains.

## Start Here

- [MVP product brief](docs/MVP_PRODUCT_BRIEF.md) — the first-product boundary.
- [UI specification](docs/UI_SPEC.md) — the interaction, accessibility, and visual contract.
- [iOS implementation plan](docs/IOS_IMPLEMENTATION_PLAN.md) — ordered vertical slices and acceptance criteria.
- [Changelog](docs/CHANGELOG.md) — shipped user-visible features on `main`.
- [Agent guidance](AGENTS.md) — engineering rules for people and coding agents.
- [Original app concept](Documentation/Breadcrumb%20App%20Concept.md) — long-term vision, not current scope.

## First Release

The first release is a private, offline reminder app with:

- A title and optional Notes context.
- An optional due date and local notification.
- Optional custom recurrence for due reminders: one weekday, day of month, or month of year.
- Reminder-scoped photo and file attachments stored locally (up to six items and 15 MB total per reminder).
- Native photo/file previews that do not alter or remove the attachment.
- Independent Priority and Important controls.
- Open and completed lists.
- Archiving and independently collapsible status sections.
- A light/dark TimeLore app icon and a responsive home-screen brand mark.
- Multi-tag organization, filtering, and home-overflow tag management.
- Tag creation, rename, color, and icon editing; deleting a tag detaches it from reminders without deleting the reminders.
- Local text search.
- SwiftData persistence.

The aim is to validate whether preserving context makes reminders more useful. Reminder recurrence and basic local photo/file attachments are part of this MVP; contact-card capture, OCR, receipt intelligence, locations, sync, and AI remain outside it.

## Prerequisites

- A Mac with the full Xcode application installed.
- An iOS Simulator supported by that Xcode installation.
- No third-party packages are planned for the MVP.

See the implementation plan for project-creation settings and the first build sequence.
