import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:permission_handler/permission_handler.dart'
    show Permission, PermissionStatus;

/// Abstraction over the platform permission calls.
///
/// The default implementation forwards to `permission_handler`. Replace it in
/// tests to drive the full dialog flow without any platform channels:
/// ```dart
/// SmartPermission.config.gateway = MyFakeGateway();
/// ```
abstract class SmartPermissionGateway {
  /// Current status of [permission].
  Future<PermissionStatus> status(Permission permission);

  /// Requests [permission] natively and returns the resulting status.
  Future<PermissionStatus> request(Permission permission);

  /// Requests all [permissions] in one native batch flow.
  Future<Map<Permission, PermissionStatus>> requestMultiple(
      List<Permission> permissions);

  /// Opens the app settings screen. Returns false when unsupported.
  Future<bool> openAppSettings();

  /// Completes once the user has plausibly returned from the settings
  /// screen, so a follow-up [status] check reflects their changes.
  Future<void> waitForSettingsReturn();
}

/// Production gateway backed by `permission_handler`.
class DefaultSmartPermissionGateway implements SmartPermissionGateway {
  const DefaultSmartPermissionGateway();

  @override
  Future<PermissionStatus> status(Permission permission) => permission.status;

  @override
  Future<PermissionStatus> request(Permission permission) =>
      permission.request();

  @override
  Future<Map<Permission, PermissionStatus>> requestMultiple(
          List<Permission> permissions) =>
      permissions.request();

  @override
  Future<bool> openAppSettings() => ph.openAppSettings();

  /// Waits for the app to go to the background (user left for settings) and
  /// come back to the foreground.
  ///
  /// Falls back to completing after a short delay if the app never leaves the
  /// foreground (some platforms open settings without backgrounding the app),
  /// and gives up after [_maxWait] if the user stays in settings.
  @override
  Future<void> waitForSettingsReturn() async {
    final binding = WidgetsBinding.instance;
    final completer = Completer<void>();
    final observer = _SettingsReturnObserver(() {
      if (!completer.isCompleted) completer.complete();
    });
    binding.addObserver(observer);
    final fallback = Timer(_foregroundFallback, () {
      if (!observer.leftApp && !completer.isCompleted) completer.complete();
    });
    try {
      await completer.future.timeout(_maxWait);
    } on TimeoutException {
      // User stayed in settings for a long time; proceed with a best-effort
      // status check.
    } finally {
      fallback.cancel();
      binding.removeObserver(observer);
    }
  }

  static const Duration _foregroundFallback = Duration(seconds: 3);
  static const Duration _maxWait = Duration(minutes: 3);
}

class _SettingsReturnObserver with WidgetsBindingObserver {
  _SettingsReturnObserver(this.onReturn);

  final VoidCallback onReturn;
  bool leftApp = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (leftApp) onReturn();
    } else {
      leftApp = true;
    }
  }
}
