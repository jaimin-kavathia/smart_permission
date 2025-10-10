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
    final status = await permission.status;
    if (status.isGranted) return true;

    final requested = await permission.request();
    if (requested.isGranted) return true;

    if (requested.isDenied) {
      final cfg = SmartPermissionConfig.instance;
      final rationale = cfg.resolveDescription(permission, message);
      final dialog = cfg.customDialogBuilder ?? showPermissionDialog;
      final resolvedTitle = cfg.resolveTitle(permission, title);
      final retry = await dialog(
        context,
        style: style,
        title: resolvedTitle ?? 'Permission required',
        message: rationale ??
            'This feature needs permission: ${permission.toString()}.',
        primaryText: okButtonText ?? 'Allow',
        secondaryText: denyButtonText ?? 'Not now',
      );
      if (retry == true) {
        final secondTry = await permission.request();
        return secondTry.isGranted;
      }
      cfg.analytics.onDenied(permission);
      return false;
    }

    if (requested.isPermanentlyDenied || requested.isRestricted) {
      final cfg = SmartPermissionConfig.instance;
      final dialog = cfg.customDialogBuilder ?? showPermissionDialog;
      final open = await dialog(
        context,
        style: style,
        title: cfg.resolveTitle(permission, title) ?? 'Permission blocked',
        message: message ??
            'Permission is disabled. You can enable it in the app settings.',
        primaryText: settingsButtonText ?? 'Open Settings',
        secondaryText: denyButtonText ?? 'Cancel',
      );
      if (open == true) {
        final opened = await openAppSettings();
        if (!opened) return false;
        final after = await permission.status;
        return after.isGranted;
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
