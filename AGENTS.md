# TimeLore Repository Guide

## Mission

Build TimeLore as an iOS reminder app that preserves the reason behind a reminder. Prove the capture → notify → complete loop before adding the broader memory-assistant vision.

The beginning phase stays deliberately small, but its interaction model now also includes:

- A persisted Important state that is separate from completion, archiving, and tags.
- Predictable directional swipe actions.
- Distinguishable default tags and filters.
- Apple-native iOS 26 navigation and presentation surfaces.

## Read First

For product or engineering work, read these files in order:

1. `README.md`
2. `docs/MVP_PRODUCT_BRIEF.md`
3. `docs/UI_SPEC.md`
4. `docs/IOS_IMPLEMENTATION_PLAN.md`

The MVP brief controls the beginning-phase product boundary. `docs/UI_SPEC.md` controls UI behavior, interaction direction, visual hierarchy, Important state, default tags, accessibility, and the separation between MVP and post-MVP designs. The implementation plan controls milestone order.

The existing founder documents are vision inputs, not an implementation backlog. If a future concept conflicts with the MVP brief or the MVP section of `docs/UI_SPEC.md`, the MVP documents win until the expansion gate is explicitly passed.

## Current Scope

The first build is local-only and supports:

- Create, view, edit, complete, reopen, and delete reminders.
- Archive and restore reminders without changing their completion state.
- Mark or unmark a reminder as Important without changing its completion or archive state.
- Store a title, optional “why,” optional due date, Important state, status, and timestamps.
- Schedule or cancel a local notification for reminders with a due date.
- Organize reminders with multiple tags and filter by All, Important, Untagged, or a selected tag.
- Seed the default tags Work, Personal, Projects, Grocery, Health, and Errands idempotently.
- Show tags using stable, distinguishable tints while retaining text labels and selection indicators.
- Show independently collapsible Open, Completed, and Archived sections.
- Search title and “why” text locally.
- Use Liquid Glass only for navigation, toolbars, search, sheets, menus, dialogs, and transient interactive controls on iOS 26.
- Render the content layer in pure white or true OLED black with restrained flat cards and thin separators.

### Required swipe behavior

- Swipe right on an open reminder: **Complete**.
- Swipe right on a completed reminder: **Reopen**.
- Swipe left on an unarchived reminder: **Flag/Unflag** and **Archive**.
- Swipe left on an archived reminder: **Flag/Unflag** and **Restore**.
- Important state must survive completion, reopening, archiving, restoring, editing, app termination, and relaunch.
- Destructive delete remains a confirmed action in the detail overflow menu; it is not a full-swipe action.

## Beginning-Phase Information Architecture

The MVP is one reminder stack, not a multi-tab life dashboard.

- Root: reminder home/list.
- Modal: new-reminder and edit-reminder sheets.
- Push destination: reminder detail.
- Presentation surfaces: tag filters, search, overflow menu, notification guidance, and confirmation dialogs.

Do not introduce the post-MVP Timeline/Today/Future/Insights tab bar into the beginning phase.

## Engineering Defaults

- Use SwiftUI for UI and SwiftData for persistence.
- Use `NavigationStack` and small feature-oriented views.
- Keep business rules outside views in testable types. Do not introduce MVVM objects that only relay stored properties.
- Wrap notification authorization and scheduling behind a protocol so tests do not invoke system services.
- Store dates as `Date`; format them only at the UI boundary.
- Model reminder status explicitly rather than inferring it from dates.
- Model Important as a persisted Boolean or equivalent explicit state; do not implement it as a tag.
- Seed default tags through an idempotent service or migration-safe operation; never create duplicates on relaunch.
- Keep tag identity independent of presentation color. Color is a stable display token, not the primary key.
- Use labels, icons, selected states, and accessibility values so color is never the only distinction.
- Prefer Apple frameworks and zero third-party dependencies for the MVP.
- Keep the app functional offline and collect no data by default.
- Prefer standard Xcode 26/SwiftUI navigation and presentation APIs so the system supplies Liquid Glass. Do not imitate Liquid Glass with custom blur stacks.
- Keep Liquid Glass out of reminder cards and other content surfaces.

## Visual Source of Truth

The final boards referenced by `docs/UI_SPEC.md` live in `docs/ui/`:

- `mvp-home-tags-swipes.webp`
- `mvp-capture-detail-dark.webp`
- `post-mvp-core-navigation.webp`
- `post-mvp-capture-life-search.webp`
- `post-mvp-connected-spaces-trust.webp`

Boards communicate hierarchy and flow, not fixed pixel coordinates. Standard controls, safe areas, Dynamic Type, and current SDK behavior take precedence over literal screenshot measurements.

## Proposed Source Layout

```text
TimeLore/
├── App/
├── Features/
│   └── Reminders/
├── Models/
├── Services/
├── Shared/
└── Resources/
TimeLoreTests/
TimeLoreUITests/
docs/
└── ui/
```

Use this layout as files are needed; do not create empty folders merely to match it.

## Change Workflow

1. Identify the next unchecked milestone in `docs/IOS_IMPLEMENTATION_PLAN.md`.
2. For UI work, locate the matching MVP page, interaction, and acceptance criteria in `docs/UI_SPEC.md`.
3. Implement the smallest end-to-end slice that produces user-visible value.
4. Add or update tests for domain rules, persistence, swipe direction, default-tag seeding, filters, and service behavior.
5. Build and test using the repository’s shared Xcode scheme.
6. Update documentation only when scope, architecture, interaction contracts, or setup changed.

Use the repo skill at `.agents/skills/breadcrumb-ios-development/SKILL.md` for implementation and review tasks.

## Post-MVP Guardrail

The following are concept-only until the MVP trial proves that users repeatedly add and retrieve context:

- Timeline, Today, Future, and Insights tabs.
- Memory, Note, Place, Person, Photo, Receipt, and Project spaces.
- OCR, receipt intelligence, attachments, semantic or conversational search, summaries, suggestions, weekly review, travel mode, people/place relationships, and cloud sync.

Post-MVP pages are documented so later architecture has a coherent direction. Their presence in `docs/UI_SPEC.md` is not implementation approval.

## Validation

Once an Xcode project exists, prefer commands equivalent to:

```bash
xcodebuild -scheme TimeLore -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme TimeLore -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Discover available simulators first and substitute an installed device. Do not claim a build or test passed unless the command was run successfully. If full Xcode is unavailable, state that limitation and still run any checks that are available.

## Definition of Done for a Slice

- The acceptance criteria in the implementation plan and relevant MVP section of `docs/UI_SPEC.md` are met.
- Empty, error, permission-denied, destructive-action, filtered-empty, and relevant edge states are handled.
- Accessibility labels, accessibility values, Dynamic Type, contrast, and Reduced Transparency remain usable.
- Swipe direction and revealed actions match the specification.
- Important state and default tags persist without duplication or state coupling.
- Light mode uses a pure white content layer; dark mode uses true OLED black where practical.
- Liquid Glass is confined to functional navigation/presentation layers.
- New business logic has focused tests.
- No post-MVP feature is pulled into the change accidentally.
- The working tree contains no unrelated generated artifacts or secrets.
