import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ui/permission_dialog_style.dart';
import 'core/smart_permission_core.dart';
import 'core/smart_permission_result.dart';
import 'core/config.dart';

/// Simple, opinionated permission manager.
///
/// What this class does for you:
/// - Requests a permission and inspects its current status
/// - If first time: lets the native system sheet appear (optionally after a
///   rationale dialog, see [SmartPermissionConfig.showRationaleBeforeRequest])
/// - If denied: shows a rationale/description dialog with configurable style
/// - If permanently denied: shows a dialog offering to open Settings, then
///   waits for the user to return before re-checking
/// - If restricted (e.g. parental controls): shows an informational dialog
/// - Supports batch requests with a single native flow and combined dialogs
/// - Pulls titles/descriptions from built-in defaults, per-permission
///   providers, or call-site overrides
class SmartPermission {
  const SmartPermission._();

  static const SmartPermissionCore _core = SmartPermissionCore();

  /// Configure global behaviors like dialog style, strings, analytics,
  /// rationale, and a navigator key for showing dialogs without a context.
  static SmartPermissionConfig get config => SmartPermissionConfig.instance;

  /// Requests [permission] and handles the full dialog flow.
  /// Returns true when the feature can be used (granted, limited, or
  /// provisional). Use [requestResult] when you need to know *why* a request
  /// failed.
  ///
  /// Usage:
  /// ```dart
  /// final ok = await SmartPermission.request(
  ///   context,
  ///   permission: Permission.location,
  ///   description: 'We need location to show nearby stores.',
  /// );
  /// ```
  static Future<bool> request(
    BuildContext context, {
    required Permission permission,
    PermissionDialogStyle? style,
    String? title,
    String? description,
    String? denyButtonText,
    String? settingsButtonText,
    String? okButtonText,
    bool? showRationaleFirst,
  }) async {
    final result = await _core.requestResult(
      context,
      permission: permission,
      style: style,
      title: title,
      message: description,
      denyButtonText: denyButtonText,
      settingsButtonText: settingsButtonText,
      okButtonText: okButtonText,
      showRationaleFirst: showRationaleFirst,
    );
    return result.canProceed;
  }

  /// Like [request], but returns a [SmartPermissionResult] describing the
  /// outcome (granted, denied, permanentlyDenied, restricted, ...).
  ///
  /// [context] is optional when [SmartPermissionConfig.navigatorKey] is set;
  /// without either, dialogs are skipped and only the native flow runs.
  ///
  /// Usage:
  /// ```dart
  /// final result = await SmartPermission.requestResult(
  ///   permission: Permission.camera,
  ///   context: context,
  /// );
  /// if (result.canProceed) openCamera();
  /// ```
  static Future<SmartPermissionResult> requestResult({
    required Permission permission,
    BuildContext? context,
    PermissionDialogStyle? style,
    String? title,
    String? description,
    String? denyButtonText,
    String? settingsButtonText,
    String? okButtonText,
    bool? showRationaleFirst,
  }) {
    return _core.requestResult(
      context,
      permission: permission,
      style: style,
      title: title,
      message: description,
      denyButtonText: denyButtonText,
      settingsButtonText: settingsButtonText,
      okButtonText: okButtonText,
      showRationaleFirst: showRationaleFirst,
    );
  }

  /// Requests multiple [permissions] in one native batch flow and returns a
  /// map of "can proceed" booleans. Still-denied permissions are gathered
  /// into a single combined rationale dialog (and a single settings dialog
  /// for permanently denied ones) instead of one dialog per permission.
  ///
  /// Usage:
  /// ```dart
  /// final results = await SmartPermission.requestMultiple(
  ///   context,
  ///   permissions: [Permission.camera, Permission.microphone],
  /// );
  /// ```
  static Future<Map<Permission, bool>> requestMultiple(
    BuildContext context, {
    required List<Permission> permissions,
    PermissionDialogStyle? style,
    String? title,
    String? description,
    String? denyButtonText,
    String? settingsButtonText,
    String? okButtonText,
  }) async {
    final results = await _core.requestMultipleResults(
      context,
      permissions: permissions,
      style: style,
      title: title,
      message: description,
      denyButtonText: denyButtonText,
      settingsButtonText: settingsButtonText,
      okButtonText: okButtonText,
    );
    return results.map((p, r) => MapEntry(p, r.canProceed));
  }

  /// Like [requestMultiple], but returns a [SmartPermissionResult] per
  /// permission. [context] is optional when
  /// [SmartPermissionConfig.navigatorKey] is set.
  static Future<Map<Permission, SmartPermissionResult>> requestMultipleResults({
    required List<Permission> permissions,
    BuildContext? context,
    PermissionDialogStyle? style,
    String? title,
    String? description,
    String? denyButtonText,
    String? settingsButtonText,
    String? okButtonText,
  }) {
    return _core.requestMultipleResults(
      context,
      permissions: permissions,
      style: style,
      title: title,
      message: description,
      denyButtonText: denyButtonText,
      settingsButtonText: settingsButtonText,
      okButtonText: okButtonText,
    );
  }
}
