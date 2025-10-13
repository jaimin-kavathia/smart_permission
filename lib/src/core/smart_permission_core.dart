import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ui/dialogs.dart';
import '../ui/permission_dialog_style.dart';
import 'config.dart';

/// Core implementation of the permission request flows.
///
/// Handles the branching logic for first request, denied, permanently denied,
/// showing dialogs, and returning the final granted state.
class SmartPermissionCore {
  const SmartPermissionCore();

  Future<bool> request(
    BuildContext context, {
    required Permission permission,
    PermissionDialogStyle style = PermissionDialogStyle.adaptive,
    String? title,
    String? message,
    String? denyButtonText,
    String? settingsButtonText,
    String? okButtonText,
  }) async {
    PermissionStatus status;
    try {
      status = await permission.status;
    } catch (e, st) {
      debugPrint(
          '[smart_permission] Failed to read status for $permission: $e');
      debugPrint('$st');
      return false;
    }
    if (status.isGranted) return true;

    PermissionStatus requested;
    try {
      requested = await permission.request();
    } catch (e, st) {
      debugPrint('[smart_permission] Request threw for $permission: $e');
      debugPrint('$st');
      return false;
    }
    if (requested.isGranted) return true;

    if (requested.isDenied) {
      final cfg = SmartPermissionConfig.instance;
      final rationale = cfg.resolveDescription(permission, message);
      final dialog = cfg.customDialogBuilder ?? showPermissionDialog;
      final resolvedTitle = cfg.resolveTitle(permission, title);
      if (!context.mounted) return false;
      bool? retry;
      try {
        retry = await dialog(
          context,
          style: style,
          title: resolvedTitle ?? 'Permission required',
          message: rationale ??
              'This feature needs permission: ${permission.toString()}.',
          primaryText: okButtonText ?? 'Allow',
          secondaryText: denyButtonText ?? 'Not now',
        );
      } catch (e, st) {
        debugPrint(
            '[smart_permission] Rationale dialog failed for $permission: $e');
        debugPrint('$st');
        return false;
      }
      if (retry == true) {
        try {
          final secondTry = await permission.request();
          return secondTry.isGranted;
        } catch (e, st) {
          debugPrint(
              '[smart_permission] Second request threw for $permission: $e');
          debugPrint('$st');
          return false;
        }
      }
      cfg.analytics.onDenied(permission);
      return false;
    }

    if (requested.isPermanentlyDenied || requested.isRestricted) {
      final cfg = SmartPermissionConfig.instance;
      final dialog = cfg.customDialogBuilder ?? showPermissionDialog;
      if (!context.mounted) return false;
      bool? open;
      try {
        open = await dialog(
          context,
          style: style,
          title: cfg.resolveTitle(permission, title) ?? 'Permission blocked',
          message: message ??
              'Permission is disabled. You can enable it in the app settings.',
          primaryText: settingsButtonText ?? 'Open Settings',
          secondaryText: denyButtonText ?? 'Cancel',
        );
      } catch (e, st) {
        debugPrint(
            '[smart_permission] Settings prompt failed for $permission: $e');
        debugPrint('$st');
        return false;
      }
      if (open == true) {
        bool opened = false;
        try {
          opened = await openAppSettings();
        } catch (e, st) {
          debugPrint('[smart_permission] openAppSettings threw: $e');
          debugPrint('$st');
          opened = false;
        }
        if (!opened) {
          // As a fallback (e.g., web or unsupported), inform the user to enable
          // permission manually from system/browser settings.
          if (!context.mounted) return false;
          try {
            await (cfg.customDialogBuilder ?? showPermissionDialog)(
              context,
              style: style,
              title: cfg.resolveTitle(permission, title) ??
                  'Open settings manually',
              message: message ??
                  'We couldn\'t open settings automatically. Please enable this permission in your system or browser settings and return to the app.',
              primaryText: okButtonText ?? 'OK',
              secondaryText: denyButtonText ?? 'Cancel',
            );
          } catch (e, st) {
            debugPrint(
                '[smart_permission] Fallback settings dialog failed: $e');
            debugPrint('$st');
          }
          return false;
        }
        try {
          final after = await permission.status;
          return after.isGranted;
        } catch (e, st) {
          debugPrint(
              '[smart_permission] Status after settings failed for $permission: $e');
          debugPrint('$st');
          return false;
        }
      }
      cfg.analytics.onPermanentlyDenied(permission);
      return false;
    }

    if (requested.isLimited) {
      return true;
    }

    return false;
  }

  Future<Map<Permission, bool>> requestMultiple(
    BuildContext context, {
    required List<Permission> permissions,
    PermissionDialogStyle style = PermissionDialogStyle.adaptive,
    String? title,
    String? message,
    String? denyButtonText,
    String? settingsButtonText,
    String? okButtonText,
  }) async {
    final Map<Permission, bool> result = <Permission, bool>{};
    for (final p in permissions) {
      final granted = await request(
        context,
        permission: p,
        style: style,
        title: title,
        message: message,
        denyButtonText: denyButtonText,
        settingsButtonText: settingsButtonText,
        okButtonText: okButtonText,
      );
      result[p] = granted;
    }
    return result;
  }
}
