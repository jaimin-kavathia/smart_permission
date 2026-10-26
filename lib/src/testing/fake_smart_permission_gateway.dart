import 'package:permission_handler/permission_handler.dart'
    show Permission, PermissionStatus;

import '../core/permission_gateway.dart';

/// In-memory [SmartPermissionGateway] for widget and unit tests.
///
/// Drives every `SmartPermission` flow (and `PermissionGate`) without
/// platform channels:
/// ```dart
/// final fake = FakeSmartPermissionGateway()
///   ..statuses[Permission.camera] = PermissionStatus.denied
///   ..requestResults[Permission.camera] = [PermissionStatus.granted];
/// SmartPermission.config.gateway = fake;
///
/// // ... pump your widget, tap the button that requests the camera ...
///
/// expect(fake.requestedPermissions, [Permission.camera]);
/// SmartPermission.config.resetToDefaults();
/// ```
class FakeSmartPermissionGateway implements SmartPermissionGateway {
  /// Creates a fake with optional initial [statuses].
  FakeSmartPermissionGateway({Map<Permission, PermissionStatus>? statuses}) {
    if (statuses != null) this.statuses.addAll(statuses);
  }

  /// Current status per permission. Unlisted permissions are `denied`.
  /// Updated by every request.
  final Map<Permission, PermissionStatus> statuses =
      <Permission, PermissionStatus>{};

  /// Statuses returned by successive native requests, per permission. When
  /// a queue is empty (or absent) a request returns the current status.
  final Map<Permission, List<PermissionStatus>> requestResults =
      <Permission, List<PermissionStatus>>{};

  /// Applied to [statuses] when the user "returns from settings" (during
  /// [waitForSettingsReturn]).
  final Map<Permission, PermissionStatus> statusesAfterSettings =
      <Permission, PermissionStatus>{};

  /// Every permission passed to a native request, in order.
  final List<Permission> requestedPermissions = <Permission>[];

  /// What [openAppSettings] returns; set to false to simulate a platform
  /// that cannot open settings (e.g. web).
  bool canOpenSettings = true;

  /// How many times [openAppSettings] was called.
  int openSettingsCalls = 0;

  /// How many times [waitForSettingsReturn] was called.
  int waitForSettingsReturnCalls = 0;

  /// When set, [status] throws this.
  Object? statusError;

  /// When set, [request] and [requestMultiple] throw this.
  Object? requestError;

  /// Mimics Android, where [status] reports `denied` for a permanently
  /// denied permission and only a request returns `permanentlyDenied`.
  bool androidStatusSemantics = false;

  @override
  Future<PermissionStatus> status(Permission permission) async {
    final error = statusError;
    if (error != null) throw error;
    final s = statuses[permission] ?? PermissionStatus.denied;
    if (androidStatusSemantics && s == PermissionStatus.permanentlyDenied) {
      return PermissionStatus.denied;
    }
    return s;
  }

  @override
  Future<PermissionStatus> request(Permission permission) async {
    final error = requestError;
    if (error != null) throw error;
    requestedPermissions.add(permission);
    final queue = requestResults[permission];
    final next = (queue != null && queue.isNotEmpty)
        ? queue.removeAt(0)
        : (statuses[permission] ?? PermissionStatus.denied);
    statuses[permission] = next;
    return next;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestMultiple(
      List<Permission> permissions) async {
    return {
      for (final p in permissions) p: await request(p),
    };
  }

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalls++;
    return canOpenSettings;
  }

  @override
  Future<void> waitForSettingsReturn() async {
    waitForSettingsReturnCalls++;
    statuses.addAll(statusesAfterSettings);
  }
}
