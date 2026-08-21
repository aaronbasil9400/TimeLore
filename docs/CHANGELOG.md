# Changelog

This log records user-visible features that have landed on `main`. It is not a roadmap; proposed work belongs in the product brief and implementation plan.

## 2026-08-21 — Brand refresh and tag management

### Added

- TimeLore app-icon and wordmark assets with coordinated light and dark appearances.
- A responsive TimeLore wordmark on Reminder Home that compacts while the list scrolls.
- A refined home visual system: restrained content surfaces, clearer tag chips, an overflow menu, and a dedicated primary create action.
- **Manage Tags** in the home overflow menu.
- Tag creation, rename, color selection, and supported SF Symbol selection for default and custom tags.
- Tag usage counts and accessible descriptions in Manage Tags.

### Changed

- Reminder Home now keeps its wordmark and grouped Overflow/Plus Liquid Glass pill on one row at rest; the compact scrolling header overlays content without a blank navigation-bar gap or scroll jitter.
- Tag presentation is persisted with the tag instead of being inferred solely from its name.
- Tag filters use stable tag identity, so a renamed tag remains selected.
- Recurring-series tag templates stay in sync when a tag is renamed or deleted.
- Default tags keep a stable internal identity: renamed defaults are not re-seeded under their original names, and deleted defaults remain deleted until explicitly recreated.

### Safety

- Deleting an unused tag removes the tag immediately.
- Deleting an in-use tag requires confirmation, clearly states the number of affected reminders, and only detaches the tag. It never deletes, archives, completes, or otherwise changes a reminder.

### Verification recorded with the feature

- Automated coverage was added for tag seeding, rename/delete behavior, recurring-template updates, duplicate prevention, and the home-overflow tag-management flow.
- The tag-management layout was checked in both light and dark appearances.
