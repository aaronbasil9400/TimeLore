# TimeLore MVP Product Brief

**Status: In acceptance review.** The core reminder experience, custom recurrence, and reminder-scoped photo/file attachments are implemented. Device acceptance for notifications, system pickers, previews, accessibility, and timezone behavior remains before the MVP trial.

## Product Bet

People often ignore or delete old reminders because the task text no longer explains the original intent. TimeLore tests whether lightweight Notes and attached context make reminders easier to act on later.

## Target User

Start with one audience: a busy individual who creates personal follow-ups, errands, and time-sensitive tasks on an iPhone. Shared household and professional-team workflows are later markets.

## Core Job

> When I capture something I must remember, help me record enough context to understand and complete it later without reconstructing the reason.

## Core Loop

1. Capture a reminder in a few seconds.
2. Optionally record Notes, supporting attachments, when it is due, and whether it repeats.
3. Receive a local notification at the chosen time.
4. Reopen the reminder with its context intact.
5. Complete it and retain it in local history; recurring commitments continue predictably.

## MVP Requirements

### Reminder data

- Title: required, trimmed, 1–200 characters.
- Notes: optional plain text, up to 2,000 characters.
- Due date: optional.
- Repeat rule: optional and available only when a due date is set.
- Repeat options: custom weekly (one weekday), monthly (day 1–31), or yearly (one month and the due-date day); an unavailable day uses the final day of that month.
- Priority: none, level 1 (`!`), level 2 (`!!`), or level 3 (`!!!`), separate from Important.
- Status: open or completed.
- Created and last-updated timestamps.
- Completion timestamp when completed.
- Archive timestamp when hidden from the main workflow.
- Zero or more tags.
- Zero or more local reminder attachments: photo or file, up to six items and 15 MB combined per reminder.

### Experiences

- Open reminders list, ordered by dated reminders first and then creation date by default, with an explicit Priority sort option.
- Completed reminders list, newest completion first.
- Create and edit form with inline validation.
- Reminder detail view.
- Complete and reopen actions.
- Archive and restore actions that preserve completion status.
- Delete with confirmation.
- Independently collapsible Open, Completed, and Archived sections whose state persists.
- Multi-tag creation, selection, display, and filtering.
- Case-insensitive local search across title and Notes.
- Local notification request only when the user first saves a dated reminder.
- Create, inspect, edit, and stop a recurring reminder without duplicating or losing occurrence history.
- When editing a recurring reminder, explicitly choose whether the edit applies to this occurrence or this and future occurrences.
- Add, preview, and remove photo and file attachments from reminder create/edit/detail flows.
- Photos show a visual preview; supported files show a thumbnail and open with the system preview. Opening a preview never removes the attachment.
- Keep attachment data local and usable offline.
- Clear in-app behavior when notification permission is denied.

## Non-Goals

- Receipt scanning or OCR.
- Contact-card capture, audio attachments, camera/OCR workflows, and attachment intelligence.
- Broad contact import, background contact syncing, or a people relationship graph.
- Location-triggered reminders.
- Natural-language date parsing.
- AI summaries, semantic search, recommendations, or predictions.
- Projects, people, purchases, memory graphs, or timelines beyond reminder history.
- Cloud sync, accounts, sharing, widgets, watch apps, or subscriptions.

## Product Principles

- **Context without friction:** Notes and attachments are prominent but never required.
- **Local first:** the first build works without a network or account.
- **Trustworthy reminders:** notification state must match saved reminder state.
- **Calm defaults:** no gamification, urgency scoring, or noisy prompts.
- **Accessible by default:** support Dynamic Type, VoiceOver labels, and system colors.

## Success Measures for a Small Test

Run a two-week device or TestFlight trial with 5–10 people:

- At least 70% can create their first reminder without help.
- Median capture time is under 15 seconds.
- At least half of dated reminders include Notes after one week.
- Participants can explain whether Notes or an attachment helped them act on an older reminder.
- No saved reminder is lost during normal create, edit, terminate, and relaunch flows.
- Recurring occurrences do not duplicate, skip, or overwrite completed history in normal use.
- Reminder attachments remain available offline after relaunch and are removed when the user deletes them.

Avoid building analytics infrastructure solely for the first internal test; interviews and a short survey are sufficient.

## Expansion Gate

Recurring reminders and basic reminder-scoped photo/file attachments are approved within this MVP and do not pass the expansion gate. Contact-card capture, OCR, independent memory/photo spaces, semantic intelligence, relationships, and sync remain gated until a future product decision explicitly approves them.
