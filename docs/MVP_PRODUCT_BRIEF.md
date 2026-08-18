# Breadcrumb MVP Product Brief

## Product Bet

People often ignore or delete old reminders because the task text no longer explains the original intent. Breadcrumb tests whether adding a lightweight “why” field makes reminders easier to act on later.

## Target User

Start with one audience: a busy individual who creates personal follow-ups, errands, and time-sensitive tasks on an iPhone. Shared household and professional-team workflows are later markets.

## Core Job

> When I capture something I must remember, help me record enough context to understand and complete it later without reconstructing the reason.

## Core Loop

1. Capture a reminder in a few seconds.
2. Optionally record why it matters and when it is due.
3. Receive a local notification at the chosen time.
4. Reopen the reminder with its context intact.
5. Complete it and retain it in local history.

## MVP Requirements

### Reminder data

- Title: required, trimmed, 1–200 characters.
- Why: optional plain text, up to 2,000 characters.
- Due date: optional.
- Status: open or completed.
- Created and last-updated timestamps.
- Completion timestamp when completed.

### Experiences

- Open reminders list, ordered by dated reminders first and then creation date.
- Completed reminders list, newest completion first.
- Create and edit form with inline validation.
- Reminder detail view.
- Complete and reopen actions.
- Delete with confirmation.
- Case-insensitive local search across title and “why.”
- Local notification request only when the user first saves a dated reminder.
- Clear in-app behavior when notification permission is denied.

## Non-Goals

- Receipt scanning or OCR.
- Photo or audio attachments.
- Location-triggered reminders.
- Natural-language date parsing.
- AI summaries, semantic search, recommendations, or predictions.
- Projects, people, purchases, memory graphs, or timelines beyond reminder history.
- Cloud sync, accounts, sharing, widgets, watch apps, or subscriptions.

## Product Principles

- **Context without friction:** “Why” is prominent but never required.
- **Local first:** the first build works without a network or account.
- **Trustworthy reminders:** notification state must match saved reminder state.
- **Calm defaults:** no gamification, urgency scoring, or noisy prompts.
- **Accessible by default:** support Dynamic Type, VoiceOver labels, and system colors.

## Success Measures for a Small Test

Run a two-week device or TestFlight trial with 5–10 people:

- At least 70% can create their first reminder without help.
- Median capture time is under 15 seconds.
- At least half of dated reminders include “why” after one week.
- Participants can explain whether “why” helped them act on an older reminder.
- No saved reminder is lost during normal create, edit, terminate, and relaunch flows.

Avoid building analytics infrastructure solely for the first internal test; interviews and a short survey are sufficient.

## Expansion Gate

Do not start the full memory platform until the core test shows that users repeatedly add context and find it useful. Choose the next feature from observed demand, not the founder inventory. Likely experiments are quick capture, attachments, or sync—one at a time.

