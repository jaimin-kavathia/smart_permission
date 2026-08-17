## 1.0.1

Documentation polish.

- README: fixed the result-API example (switch cases containing only
  comments silently fall through in Dart 3; replaced with an if/else chain
  using `result.canProceed`)
- README: refreshed the feature lists to cover the 1.0.0 capabilities
  (rich results, restricted flow, settings-return wait, rationale-first,
  localization, analytics hooks, test gateway)

## 1.0.0

First stable release. The 0.x API keeps working — `request(...)` and
`requestMultiple(...)` are unchanged in signature and return type. See the
README's "Migrating from 0.x" section.

### Dependencies

- Upgraded `permission_handler` to ^13.0.1. **Android apps must build with
  `compileSdk 37`** — Flutter's default is still 36, so set
  `compileSdk = 37` explicitly in `android/app/build.gradle(.kts)`.

### New

- `SmartPermission.requestResult` / `requestMultipleResults`: return a
  `SmartPermissionResult` (granted / limited / provisional / denied /
  permanentlyDenied / restricted / error) instead of a bare bool. `context`
  is optional when `config.navigatorKey` is set.
- `SmartPermissionStrings`: every built-in dialog string is now replaceable
  for localization via `config.strings`.
- `showRationaleFirst` (per call) and `config.showRationaleBeforeRequest`
  (global): show the explanation dialog *before* the first native prompt.
- `config.navigatorKey` is now actually used: set it to show dialogs without
  passing a `BuildContext`.
- `config.defaultDialogStyle` is now actually used as the fallback style.
- `config.onError`: observe internal platform/dialog errors (e.g. to forward
  to Crashlytics).
- `config.gateway` (`SmartPermissionGateway`): injectable platform access so
  apps can widget-test their permission flows without platform channels.
- `config.resetToDefaults()` for tests.
- Analytics: new `onRequested`, `onGranted`, and `onRestricted` hooks, and
  the denied hook now also fires when the user denies the native prompt after
  accepting the rationale. `InMemoryPermissionAnalyticsTracker` gained
  matching counters.
- Built-in title/description for `Permission.accessLocalNetwork`
  (Android 17, new in permission_handler 13).

### Fixed

- Settings flow: after "Open Settings" the package now waits for the user to
  return to the app before re-checking the permission (previously it
  re-checked immediately, which almost always reported a stale denial).
- `restricted` (e.g. parental controls) no longer sends users to app settings
  — settings cannot fix a restricted permission; an informational dialog is
  shown instead.
- `provisional` (iOS provisional notifications) and already-`limited`
  statuses are treated as usable instead of re-prompting.
- The permanently-denied dialog now uses the same
  description-resolution chain (explicit > provider > built-in) as the
  rationale dialog.
- Removed the `dart:io` platform check that could crash on web and made the
  package incompatible with WebAssembly. The package (and its updated web
  dependency chain) now compiles with `flutter build web --wasm`.

### Changed

- `requestMultiple` now runs one native batch flow and shows a single
  combined rationale dialog (and a single combined settings dialog) instead
  of a full per-permission dialog sequence.
- Analytics trackers should `extends PermissionAnalyticsTracker`; if you used
  `implements`, add the new hooks or switch to `extends`.
- Packaging: `install.sh` and the README hero image are no longer shipped in
  the package archive (README now loads the image from GitHub).

## 0.0.3

Platform support and example updates.

- Platforms: Declared support for Android, iOS, Web, and Windows
- Core: Added robust try/catch + debug logs around permission flows
- Core: Fallback dialog if opening app settings is unsupported/fails (web/windows)
- Example: Added "Location (web/windows)" button to test browser/system flows
- Example: Scaffolded Windows runner; removed macOS from declared platforms
- Tooling: Project formatted and analyzed via FVM

## 0.0.2

Improvements and maintenance.

- README: Added full‑width hero image and small copy refinements
- Pubspec: Shortened description to 60–180 chars for SEO/snippet display
- Lints: Fixed dangling library doc by adding `library smart_permission;`
- Lints: Addressed `use_build_context_synchronously` with `context.mounted` checks
- API: Replaced deprecated `Permission.calendar` with `calendarWriteOnly` and `calendarFullAccess`
- Example: Added curly braces for single‑line if statements to satisfy lints

## 0.0.1

Initial release.

- Core: Simple permission API wrapping `permission_handler`
  - Single: `SmartPermission.request(context, permission: ...)`
  - Batch: `SmartPermission.requestMultiple(context, permissions: [...])`
- UI: Adaptive dialogs (Material/Cupertino) with configurable style
- Config: Global theming (light/dark, primaryColor)
- Content: Built-in per-permission titles and descriptions with override providers
- Customization: `customDialogBuilder` hook
- Analytics: Hook interface + default in-memory tracker
- Re-exports: `Permission` types so apps only import this package
- Example app: Android/iOS demo with theme toggle, style selector, custom builder demo
- Platform refs: Example `AndroidManifest.xml`, iOS `Info.plist` and Podfile macros
- Tooling: README, GitHub CI (format, analyze, test), starter tests
