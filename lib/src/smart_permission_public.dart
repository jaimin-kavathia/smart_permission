import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ui/permission_dialog_style.dart';
import 'core/smart_permission_core.dart';
import 'core/config.dart';

/// Simple, opinionated permission manager.
///
/// What this class does for you:
/// - Requests a permission and inspects its current status
/// - If first time: lets the native system sheet appear
/// - If denied: shows a rationale/description dialog with configurable style
/// - If permanently denied: shows a dialog offering to open Settings
/// - Supports batch requests with [requestMultiple]
/// - Pulls titles/descriptions from built‑in defaults, per‑permission providers, or call‑site overrides
class SmartPermission {
  const SmartPermission._();

  static final SmartPermissionCore _core = SmartPermissionCore();

  /// Configure global behaviors like dialog style, analytics, rationale, and a navigator key
  /// for showing dialogs without passing a context.
  static SmartPermissionConfig get config => SmartPermissionConfig.instance;

  /// Requests [permission] and handles dialog flows for denied/permanentlyDenied.
  /// Returns true when granted.
  ///
  /// Usage:
  /// ```dart
  /// final ok = await SmartPermission.request(
  ///   context,
  ///   permission: Permission.location,
  ///   style: PermissionDialogStyle.adaptive,
  ///   description: 'We need location to show nearby stores.',
  /// );
  /// ```
  static Future<bool> request(
    BuildContext context, {
    required Permission permission,
    PermissionDialogStyle style = PermissionDialogStyle.adaptive,
    String? title,
    String? description,
    String? denyButtonText,
    String? settingsButtonText,
    String? okButtonText,
  }) {
    return _core.request(
      context,
      permission: permission,
      style: style,
      title: title,
      message: description,
      denyButtonText: denyButtonText,
      settingsButtonText: settingsButtonText,
      okButtonText: okButtonText,
    );
  }

  /// Requests multiple [permissions] sequentially and returns a map of results.
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
    PermissionDialogStyle style = PermissionDialogStyle.adaptive,
    String? title,
    String? description,
    String? denyButtonText,
    String? settingsButtonText,
    String? okButtonText,
  }) {
    return _core.requestMultiple(
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
