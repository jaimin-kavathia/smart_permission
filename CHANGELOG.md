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
