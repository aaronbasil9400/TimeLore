---
name: breadcrumb-ios-development
description: Build, change, test, or review the TimeLore iOS app in small Xcode-first vertical slices. Use for TimeLore Swift, SwiftUI, SwiftData, local-notification, reminder-domain, accessibility, test, architecture, or MVP implementation tasks in this repository.
---

# TimeLore iOS Development

## Establish Context

Read the repository root `AGENTS.md`, then `docs/MVP_PRODUCT_BRIEF.md` and `docs/IOS_IMPLEMENTATION_PLAN.md`. Treat the MVP brief as the current scope and older founder documents as long-term inputs.

Inspect the repository and working tree before editing. Preserve user changes and follow any more specific `AGENTS.md` encountered below the root.

## Choose the Slice

Find the first relevant incomplete milestone in the implementation plan. Restate its observable acceptance criteria internally and implement the smallest end-to-end change that meets them.

Do not introduce deferred platform features to “prepare for later.” Add an abstraction only when it creates a test seam for current behavior, such as the notification client.

## Implement

- Prefer SwiftUI, SwiftData, Apple frameworks, and no external dependencies.
- Keep views responsible for presentation and interaction, not domain rules.
- Keep reminder validation, transitions, ordering, and notification decisions deterministic and unit-testable.
- Use a reminder UUID string as the local-notification request identifier.
- Make previews and tests use an in-memory SwiftData container.
- Handle empty, invalid, permission-denied, and destructive-action states.
- Preserve offline operation, system colors, Dynamic Type, and VoiceOver semantics.

If the Xcode project has not been created, follow the bootstrap settings in the implementation plan and avoid inventing signing values. If full Xcode is unavailable, prepare only files that can be verified honestly and state what remains to run in Xcode.

## Verify

Discover available schemes and simulators before choosing a destination. Build the shared `TimeLore` scheme, then run focused tests and the full suite when feasible.

Never report a successful build, test, notification delivery, or simulator flow unless it was observed. Separate automated verification from manual device checks.

Review the final diff for accidental scope expansion, generated artifacts, secrets, and unrelated edits. Update planning documents only when a decision or milestone status genuinely changed.

## Report

Lead with the user-visible outcome. List the verification performed and any Xcode, simulator, signing, notification, or manual-device verification still required.
