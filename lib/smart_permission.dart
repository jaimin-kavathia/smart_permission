// Smart Permission
//
// A tiny, opinionated wrapper around `permission_handler` that:
// - Requests a single or multiple permissions with one call
// - Shows Material/Cupertino/adaptive dialogs for denied/permanently denied
// - Offers settings redirection for permanently denied (and waits for the
//   user to return before re-checking)
// - Returns rich results via `requestResult` (granted/denied/permanentlyDenied/
//   restricted/...), with a bool convenience API
// - Provides configurable theming (light/dark, primaryColor), localizable
//   strings, analytics hooks, and an injectable gateway for testing
// - Supplies built‑in per‑permission titles and descriptions with easy overrides
// - Re‑exports `Permission` so consumers only import this package
//
// Quick start:
// ```dart
// import 'package:smart_permission/smart_permission.dart';
//
// // Optional global setup
// SmartPermission.config
//   ..brightness = Brightness.dark
//   ..primaryColor = const Color(0xFF6750A4)
//   ..titleProvider = (p) => p == Permission.location ? 'Location Access' : null
//   ..descriptionProvider = (p) => p == Permission.location
//       ? 'We need location to show nearby stores.'
//       : null;
//
// // Single permission
// final ok = await SmartPermission.request(
//   context,
//   permission: Permission.camera,
//   style: PermissionDialogStyle.adaptive,
//   description: 'We need camera to scan QR codes.',
// );
//
// // Multiple permissions
// final results = await SmartPermission.requestMultiple(
//   context,
//   permissions: [Permission.camera, Permission.microphone],
// );
// ```
export 'src/ui/permission_dialog_style.dart';
export 'src/ui/dialogs.dart' show PermissionDialogBuilder;
export 'src/smart_permission_public.dart';
export 'package:permission_handler/permission_handler.dart'
    show Permission, PermissionStatus, openAppSettings;
export 'src/core/config.dart'
    show
        SmartPermissionConfig,
        PermissionAnalyticsTracker,
        InMemoryPermissionAnalyticsTracker,
        DescriptionProvider,
        TitleProvider;
export 'src/core/smart_permission_result.dart';
export 'src/core/strings.dart';
export 'src/core/permission_gateway.dart';
