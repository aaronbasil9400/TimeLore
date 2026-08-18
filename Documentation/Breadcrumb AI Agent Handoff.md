# Breadcrumb AI Agent Handoff Package

# Project Name
Breadcrumb

# Project Vision

Breadcrumb is a Personal Memory Operating System.

The product starts as a context-aware reminder application and evolves into a searchable life memory graph.

Users should be able to ask:

- Why did I create this reminder?
- What was happening when I created it?
- What purchases, projects, people, and locations are related?
- What happened after I created it?

Long-term vision:

Become the Search Engine for Your Life.

---

# Executive Goal

Build an iOS-first application that combines:

- Reminders
- OCR Receipts
- Photos
- Voice Notes
- Projects
- Locations
- AI Search
- Timeline Views

into a unified memory graph.

---

# Success Criteria

The application succeeds when a user can:

1. Capture information in less than 10 seconds.
2. Find any captured information using natural language.
3. Understand why a reminder exists without manual note-taking.
4. Automatically receive smarter reminders based on behavior.
5. Navigate their life timeline through projects, purchases, places, and people.

---

# Product Principles

1. Context First
2. On Device First
3. Privacy First
4. Frictionless Capture
5. Search Everything
6. AI Must Explain Itself
7. Human Memory Augmentation

---

# Core Product Thesis

Existing reminder apps track tasks.

Breadcrumb tracks:

- Intent
- Context
- Evidence
- Outcomes
- Relationships

A reminder is a node in a memory graph.

---

# Primary User Personas

## Busy Professionals
- Follow-ups
- Bills
- Action items

## Parents
- Household planning
- Supplies tracking
- Shared memories

## Travelers
- Expense tracking
- Trip journaling
- Memory preservation

## Engineers
- Project tracking
- Receipt tracking
- Action history
- Failure investigations

---

# Phase 1 MVP

## Features

### Smart Reminders
- Create reminder
- Edit reminder
- Complete reminder
- Snooze reminder

### Receipt OCR
- Camera capture
- OCR extraction
- Merchant detection
- Amount extraction

### Context Engine
- Timestamp
- GPS location
- Attached images
- Notes

### Timeline
- Chronological event history

### Search
- Keyword search
- Semantic search placeholder

### Cloud Sync
- CloudKit

---

# Phase 2

## Memory Graph

Relationships:

Reminder -> Project
Reminder -> Receipt
Reminder -> Person
Reminder -> Location
Reminder -> Photo

## AI Search

Examples:

"When did I start Smart Display?"

"Show all ESP32 purchases."

"What reminders were created in Tokyo?"

---

# Phase 3

## AI Memory Assistant

Capabilities:

- Weekly Reviews
- Context Summaries
- Reminder Optimization
- Behavioral Learning
- Project Summaries

---

# Recommended Architecture

## Frontend

SwiftUI
NavigationStack
MVVM

## Storage

SwiftData
CloudKit Sync

## Apple Frameworks

Vision Framework
CoreLocation
AVFoundation
NaturalLanguage
AppIntents
WidgetKit

## AI Layer

Apple Foundation Models
Semantic Search
Embeddings
Memory Graph Ranking

---

# Data Model

## Reminder

Fields:
- id
- title
- description
- status
- dueDate
- createdDate
- projectId
- locationId

## Receipt

Fields:
- merchant
- amount
- purchaseDate
- category
- image

## Project

Fields:
- projectName
- category
- status

## Person

Fields:
- personName
- relationship

## Memory Node

Universal graph entity.

---

# Technical Requirements

## Functional

- Works offline
- Cloud sync support
- Natural language search
- OCR support
- Background notifications

## Non Functional

- App launch < 2 seconds
- Search < 500ms
- OCR < 3 seconds
- Cloud sync conflict handling

---

# Definition of Done

A feature is complete when:

- Unit tested
- UI tested
- Search indexed
- Telemetry added
- Documentation updated
- No critical crashes

---

# Validation Plan

## Stage 1

10 Test Users

Measure:

- Daily usage
- Reminders created
- Search usage

## Stage 2

50 Test Users

Measure:

- Retention
- Search frequency
- OCR usage

## Stage 3

200 Test Users

Measure:

- Weekly retention
- Subscription conversion

---

# Key Validation Questions

1. Do users care about context?
2. Do users search history frequently?
3. Does OCR drive engagement?
4. Do project spaces increase retention?
5. Is AI search valuable enough to pay for?

---

# Engineering Plan

Sprint 1
- Project setup
- SwiftData schema
- Reminder CRUD

Sprint 2
- OCR capture
- Photo storage

Sprint 3
- Timeline engine
- CloudKit sync

Sprint 4
- Search engine
- Project spaces

Sprint 5
- AI integration
- Memory graph

Sprint 6
- Beta testing

---

# Agent Responsibilities

## Product Agent
- Refine requirements
- Manage backlog
- Prioritize roadmap

## UX Agent
- User flows
- Wireframes
- Accessibility

## iOS Agent
- SwiftUI implementation
- Architecture

## Backend Agent
- CloudKit structure
- Sync strategy

## AI Agent
- Memory graph
- Search ranking
- Context summaries

## QA Agent
- Testing
- Performance validation

---

# Risks

- User onboarding complexity
- Privacy concerns
- Apple Intelligence limitations
- Poor OCR extraction quality
- Memory graph becoming noisy

---

# North Star Metric

Searches Per User Per Week

A successful Breadcrumb user should naturally search their own life.

---

# Final Objective

Do not build a better reminder app.

Build a system that helps users remember:

- What happened
- Why it happened
- What it cost
- Who was involved
- What happened next

The reminder is the entry point.

The destination is a searchable memory operating system.
