# Project identity

## Current identity

- Display name: **TimeLore**
- Xcode project: `TimeLore.xcodeproj`
- App target and Swift module: `TimeLore`
- Test targets: `TimeLoreTests`, `TimeLoreUITests`
- Stable bundle identifier: `com.breadcrumb.app`

The bundle identifier is intentionally retained from the original prototype. Do not change it solely because the display name changes; changing it later can create a separate app identity and affect installs, data, signing, and App Store continuity.

## Single source of truth for the visible name

The app target's `APP_DISPLAY_NAME` build setting in `TimeLore.xcodeproj/project.pbxproj` controls:

- The built product name.
- The generated bundle display name.
- The accessible label and fallback user-facing name exposed through `AppIdentity.displayName`.

Keep user-facing copy independent of the internal target/module name wherever practical.

## Brand assets

- `AppIcon.appiconset` contains the approved TimeLore app icon with light and dark appearances.
- `TimeLoreLogo.imageset` contains the matching light and dark wordmark used on Reminder Home.
- The home view shows the expanded wordmark and its grouped Overflow/Plus Liquid Glass pill on one row at rest; the filter rail follows below.
- While the list scrolls, a compact wordmark and the same grouped actions overlay the top of the content without reserving an empty navigation row or shifting the list.
- Maintain light-mode and dark-mode variants together; do not flatten the two treatments into a single asset with a baked-in background.

## Renaming later

The repository includes `scripts/rename-project.sh` for a future working-copy rename:

```bash
./scripts/rename-project.sh NewName
```

The script updates the Xcode project, scheme, source/test folders, Swift module references, build settings, and visible app name in one controlled change. It defaults to renaming from `TimeLore`; set `OLD_NAME` when the current internal name differs.

After running it:

1. Open the renamed `.xcodeproj` once in Xcode.
2. Confirm the shared scheme is selected.
3. Discover an installed simulator.
4. Run the build and test commands in `AGENTS.md`.
5. Review the diff for signing, bundle identifier, and asset changes before committing.

Do not rename the bundle identifier automatically unless you intentionally want a new app identity.
