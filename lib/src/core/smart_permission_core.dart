import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ui/dialogs.dart';
import '../ui/permission_dialog_style.dart';
import 'config.dart';
import 'smart_permission_result.dart';

/// Core implementation of the permission request flows.
///
/// Handles the branching logic for first request, denied, permanently denied,
/// restricted, showing dialogs, and returning the final result.
class SmartPermissionCore {
  const SmartPermissionCore();

  static SmartPermissionConfig get _cfg => SmartPermissionConfig.instance;

  /// Resolves the context to use for dialogs: the one passed by the caller,
  /// or the one from [SmartPermissionConfig.navigatorKey]. When neither is
  /// available, dialogs are skipped and only the native flow runs.
  BuildContext? _resolveContext(BuildContext? context) =>
      context ?? _cfg.navigatorKey?.currentContext;

  void _reportError(String what, Object e, StackTrace st) {
    debugPrint('[smart_permission] $what: $e');
    debugPrint('$st');
    _cfg.onError?.call(e, st);
  }

  bool _isUsable(PermissionStatus s) =>
      s.isGranted || s.isLimited || s.isProvisional;

  SmartPermissionResult _resultFor(PermissionStatus s) {
    if (s.isGranted) return SmartPermissionResult.granted;
    if (s.isLimited) return SmartPermissionResult.limited;
    if (s.isProvisional) return SmartPermissionResult.provisional;
    if (s.isPermanentlyDenied) return SmartPermissionResult.permanentlyDenied;
    if (s.isRestricted) return SmartPermissionResult.restricted;
    return SmartPermissionResult.denied;
  }

  /// Shows a dialog via the custom builder or the built-in one. Returns null
  /// when the context is gone or the dialog fails.
  Future<bool?> _showDialog(
    BuildContext context, {
    required PermissionDialogStyle style,
    required String title,
    required String message,
    required String primaryText,
    required String secondaryText,
  }) async {
    if (!context.mounted) return null;
    final dialog = _cfg.customDialogBuilder ?? showPermissionDialog;
    try {
      return await dialog(
        context,
        style: style,
        title: title,
        message: message,
        primaryText: primaryText,
        secondaryText: secondaryText,
      );
    } catch (e, st) {
      _reportError('Dialog failed', e, st);
      return null;
    }
  }

  Future<SmartPermissionResult> requestResult(
    BuildContext? context, {
    required Permission permission,
    PermissionDialogStyle? style,
    String? title,
    String? message,
    String? denyButtonText,
    String? settingsButtonText,
    String? okButtonText,
    bool? showRationaleFirst,
  }) async {
    final cfg = _cfg;
    final strings = cfg.strings;
    final effectiveStyle = style ?? cfg.defaultDialogStyle;
    final ctx = _resolveContext(context);

    PermissionStatus status;
    try {
      status = await cfg.gateway.status(permission);
    } catch (e, st) {
      _reportError('Failed to read status for $permission', e, st);
      return SmartPermissionResult.error;
    }
    if (_isUsable(status)) return _resultFor(status);

    cfg.analytics.onRequested(permission);

    // Optional explanation before the first native prompt.
    final rationaleFirst = showRationaleFirst ?? cfg.showRationaleBeforeRequest;
    var rationaleShown = false;
    if (rationaleFirst && status.isDenied && ctx != null && ctx.mounted) {
      final proceed = await _showDialog(
        ctx,
        style: effectiveStyle,
        title: cfg.resolveTitle(permission, title) ??
            strings.permissionRequiredTitle,
        message: cfg.resolveDescription(permission, message) ??
            strings.formatGenericRationale('$permission'),
        primaryText: okButtonText ?? strings.allow,
        secondaryText: denyButtonText ?? strings.notNow,
      );
      if (proceed != true) {
        cfg.analytics.onDenied(permission);
        return SmartPermissionResult.denied;
      }
      rationaleShown = true;
    }

    PermissionStatus requested;
    try {
      requested = await cfg.gateway.request(permission);
    } catch (e, st) {
      _reportError('Request threw for $permission', e, st);
      return SmartPermissionResult.error;
    }
    if (_isUsable(requested)) {
      cfg.analytics.onGranted(permission);
      return _resultFor(requested);
    }

    if (requested.isDenied) {
      // If we already explained before the prompt, don't nag again.
      if (rationaleShown || ctx == null || !ctx.mounted) {
        cfg.analytics.onDenied(permission);
        return SmartPermissionResult.denied;
      }
      final retry = await _showDialog(
        ctx,
        style: effectiveStyle,
        title: cfg.resolveTitle(permission, title) ??
            strings.permissionRequiredTitle,
        message: cfg.resolveDescription(permission, message) ??
            strings.formatGenericRationale('$permission'),
        primaryText: okButtonText ?? strings.allow,
        secondaryText: denyButtonText ?? strings.notNow,
      );
      if (retry == true) {
        PermissionStatus second;
        try {
          second = await cfg.gateway.request(permission);
        } catch (e, st) {
          _reportError('Second request threw for $permission', e, st);
          return SmartPermissionResult.error;
        }
        if (_isUsable(second)) {
          cfg.analytics.onGranted(permission);
          return _resultFor(second);
        }
        if (second.isPermanentlyDenied) {
          cfg.analytics.onPermanentlyDenied(permission);
        } else {
          cfg.analytics.onDenied(permission);
        }
        return _resultFor(second);
      }
      cfg.analytics.onDenied(permission);
      return SmartPermissionResult.denied;
    }

    if (requested.isRestricted) {
      cfg.analytics.onRestricted(permission);
      if (ctx != null && ctx.mounted) {
        // Informational only: settings cannot fix a restricted permission.
        await _showDialog(
          ctx,
          style: effectiveStyle,
          title: cfg.resolveTitle(permission, title) ??
              strings.permissionRestrictedTitle,
          message: message ?? strings.restrictedMessage,
          primaryText: okButtonText ?? strings.ok,
          secondaryText: denyButtonText ?? strings.cancel,
        );
      }
      return SmartPermissionResult.restricted;
    }

    if (requested.isPermanentlyDenied) {
      if (ctx == null || !ctx.mounted) {
        cfg.analytics.onPermanentlyDenied(permission);
        return SmartPermissionResult.permanentlyDenied;
      }
      final description = cfg.resolveDescription(permission, message);
      final blockedMessage = message ??
          (description == null || description.isEmpty
              ? strings.blockedMessage
              : '$description ${strings.blockedMessage}');
      final open = await _showDialog(
        ctx,
        style: effectiveStyle,
        title: cfg.resolveTitle(permission, title) ??
            strings.permissionBlockedTitle,
        message: blockedMessage,
        primaryText: settingsButtonText ?? strings.openSettings,
        secondaryText: denyButtonText ?? strings.cancel,
      );
      if (open != true || !ctx.mounted) {
        cfg.analytics.onPermanentlyDenied(permission);
        return SmartPermissionResult.permanentlyDenied;
      }
      final settled = await _openSettingsAndRecheck(
        ctx,
        permissions: [permission],
        style: effectiveStyle,
        okButtonText: okButtonText,
        denyButtonText: denyButtonText,
      );
      final result = settled[permission] ?? SmartPermissionResult.error;
      if (result.canProceed) {
        cfg.analytics.onGranted(permission);
      } else if (result != SmartPermissionResult.error) {
        cfg.analytics.onPermanentlyDenied(permission);
      }
      return result;
    }

    return _resultFor(requested);
  }

  /// Opens settings, waits for the user to come back, and re-checks the
  /// given permissions. Shows the manual-settings fallback dialog when
  /// settings cannot be opened.
  Future<Map<Permission, SmartPermissionResult>> _openSettingsAndRecheck(
    BuildContext context, {
    required List<Permission> permissions,
    required PermissionDialogStyle style,
    String? okButtonText,
    String? denyButtonText,
  }) async {
    final cfg = _cfg;
    final strings = cfg.strings;
    bool opened = false;
    try {
      opened = await cfg.gateway.openAppSettings();
    } catch (e, st) {
      _reportError('openAppSettings threw', e, st);
    }
    if (!opened) {
      // E.g. web or unsupported desktop: tell the user what to do instead.
      if (context.mounted) {
        await _showDialog(
          context,
          style: style,
          title: strings.openSettingsManuallyTitle,
          message: strings.openSettingsManuallyMessage,
          primaryText: okButtonText ?? strings.ok,
          secondaryText: denyButtonText ?? strings.cancel,
        );
      }
      return {
        for (final p in permissions) p: SmartPermissionResult.permanentlyDenied,
      };
    }
    try {
      await cfg.gateway.waitForSettingsReturn();
    } catch (e, st) {
      _reportError('Waiting for settings return failed', e, st);
    }
    final results = <Permission, SmartPermissionResult>{};
    for (final p in permissions) {
      try {
        results[p] = _resultFor(await cfg.gateway.status(p));
      } catch (e, st) {
        _reportError('Status after settings failed for $p', e, st);
        results[p] = SmartPermissionResult.error;
      }
    }
    return results;
  }

  Future<Map<Permission, SmartPermissionResult>> requestMultipleResults(
    BuildContext? context, {
    required List<Permission> permissions,
    PermissionDialogStyle? style,
    String? title,
    String? message,
    String? denyButtonText,
    String? settingsButtonText,
    String? okButtonText,
  }) async {
    final cfg = _cfg;
    final strings = cfg.strings;
    final effectiveStyle = style ?? cfg.defaultDialogStyle;
    final ctx = _resolveContext(context);
    final results = <Permission, SmartPermissionResult>{};

    // Skip everything already usable.
    final toRequest = <Permission>[];
    for (final p in permissions) {
      try {
        final s = await cfg.gateway.status(p);
        if (_isUsable(s)) {
          results[p] = _resultFor(s);
        } else {
          toRequest.add(p);
        }
      } catch (e, st) {
        _reportError('Failed to read status for $p', e, st);
        results[p] = SmartPermissionResult.error;
      }
    }
    if (toRequest.isEmpty) return results;
    for (final p in toRequest) {
      cfg.analytics.onRequested(p);
    }

    // One native batch flow (the OS shows its prompts back to back).
    Map<Permission, PermissionStatus> statuses;
    try {
      statuses = await cfg.gateway.requestMultiple(toRequest);
    } catch (e, st) {
      _reportError('Batch request threw', e, st);
      for (final p in toRequest) {
        results[p] = SmartPermissionResult.error;
      }
      return results;
    }

    final denied = <Permission>[];
    final blocked = <Permission>[];
    for (final p in toRequest) {
      final s = statuses[p] ?? PermissionStatus.denied;
      if (_isUsable(s)) {
        results[p] = _resultFor(s);
        cfg.analytics.onGranted(p);
      } else if (s.isPermanentlyDenied) {
        blocked.add(p);
      } else if (s.isRestricted) {
        results[p] = SmartPermissionResult.restricted;
        cfg.analytics.onRestricted(p);
      } else {
        denied.add(p);
      }
    }

    // One combined rationale dialog for everything still deniable.
    if (denied.isNotEmpty) {
      if (ctx == null || !ctx.mounted) {
        for (final p in denied) {
          results[p] = SmartPermissionResult.denied;
          cfg.analytics.onDenied(p);
        }
      } else {
        final names =
            denied.map((p) => cfg.resolveTitle(p, null) ?? '$p').join(', ');
        final retry = await _showDialog(
          ctx,
          style: effectiveStyle,
          title: title ?? strings.permissionRequiredTitle,
          message: message ?? strings.formatMultipleRationale(names),
          primaryText: okButtonText ?? strings.allow,
          secondaryText: denyButtonText ?? strings.notNow,
        );
        if (retry == true) {
          Map<Permission, PermissionStatus> second;
          try {
            second = await cfg.gateway.requestMultiple(denied);
          } catch (e, st) {
            _reportError('Batch retry threw', e, st);
            second = const {};
          }
          for (final p in denied) {
            final s = second[p] ?? PermissionStatus.denied;
            results[p] = _resultFor(s);
            if (_isUsable(s)) {
              cfg.analytics.onGranted(p);
            } else if (s.isPermanentlyDenied) {
              cfg.analytics.onPermanentlyDenied(p);
            } else {
              cfg.analytics.onDenied(p);
            }
          }
        } else {
          for (final p in denied) {
            results[p] = SmartPermissionResult.denied;
            cfg.analytics.onDenied(p);
          }
        }
      }
    }

    // One combined settings dialog for permanently denied permissions.
    if (blocked.isNotEmpty) {
      if (ctx == null || !ctx.mounted) {
        for (final p in blocked) {
          results[p] = SmartPermissionResult.permanentlyDenied;
          cfg.analytics.onPermanentlyDenied(p);
        }
      } else {
        final names =
            blocked.map((p) => cfg.resolveTitle(p, null) ?? '$p').join(', ');
        final open = await _showDialog(
          ctx,
          style: effectiveStyle,
          title: title ?? strings.permissionBlockedTitle,
          message: message ?? strings.formatMultipleBlocked(names),
          primaryText: settingsButtonText ?? strings.openSettings,
          secondaryText: denyButtonText ?? strings.cancel,
        );
        if (open == true && ctx.mounted) {
          final settled = await _openSettingsAndRecheck(
            ctx,
            permissions: blocked,
            style: effectiveStyle,
            okButtonText: okButtonText,
            denyButtonText: denyButtonText,
          );
          for (final p in blocked) {
            final r = settled[p] ?? SmartPermissionResult.error;
            results[p] = r;
            if (r.canProceed) {
              cfg.analytics.onGranted(p);
            } else if (r != SmartPermissionResult.error) {
              cfg.analytics.onPermanentlyDenied(p);
            }
          }
        } else {
          for (final p in blocked) {
            results[p] = SmartPermissionResult.permanentlyDenied;
            cfg.analytics.onPermanentlyDenied(p);
          }
        }
      }
    }

    return results;
  }
}
