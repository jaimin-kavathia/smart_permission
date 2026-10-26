import 'package:flutter_test/flutter_test.dart';
import 'package:smart_permission/smart_permission.dart';
import 'package:smart_permission/testing.dart';

void main() {
  late FakeSmartPermissionGateway gateway;

  setUp(() {
    SmartPermission.config.resetToDefaults();
    gateway = FakeSmartPermissionGateway();
    SmartPermission.config.gateway = gateway;
  });

  tearDown(() => SmartPermission.config.resetToDefaults());

  group('status', () {
    test('maps every platform status without requesting', () async {
      gateway.statuses.addAll({
        Permission.camera: PermissionStatus.granted,
        Permission.photos: PermissionStatus.limited,
        Permission.notification: PermissionStatus.provisional,
        Permission.microphone: PermissionStatus.denied,
        Permission.location: PermissionStatus.permanentlyDenied,
        Permission.contacts: PermissionStatus.restricted,
      });

      final results =
          await SmartPermission.statuses(gateway.statuses.keys.toList());

      expect(results, {
        Permission.camera: SmartPermissionResult.granted,
        Permission.photos: SmartPermissionResult.limited,
        Permission.notification: SmartPermissionResult.provisional,
        Permission.microphone: SmartPermissionResult.denied,
        Permission.location: SmartPermissionResult.permanentlyDenied,
        Permission.contacts: SmartPermissionResult.restricted,
      });
      expect(gateway.requestedPermissions, isEmpty);
    });

    test('Android: reports a permanent denial found by an earlier request',
        () async {
      gateway
        ..androidStatusSemantics = true
        ..requestResults[Permission.camera] = [
          PermissionStatus.permanentlyDenied,
        ];

      expect(await SmartPermission.status(Permission.camera),
          SmartPermissionResult.denied,
          reason: 'Android cannot tell before a request');

      await SmartPermission.requestResult(permission: Permission.camera);

      expect(await SmartPermission.status(Permission.camera),
          SmartPermissionResult.permanentlyDenied);
    });

    test('platform error returns error and reports it', () async {
      Object? reported;
      SmartPermission.config.onError = (e, _) => reported = e;
      gateway.statusError = StateError('boom');

      expect(await SmartPermission.status(Permission.camera),
          SmartPermissionResult.error);
      expect(reported, isA<StateError>());
    });
  });

  group('hasPermission', () {
    test('true for usable statuses, false otherwise', () async {
      gateway.statuses
        ..[Permission.photos] = PermissionStatus.limited
        ..[Permission.camera] = PermissionStatus.denied;

      expect(await SmartPermission.hasPermission(Permission.photos), isTrue);
      expect(await SmartPermission.hasPermission(Permission.camera), isFalse);
      expect(gateway.requestedPermissions, isEmpty);
    });
  });

  group('openSettings', () {
    test('forwards to the gateway', () async {
      expect(await SmartPermission.openSettings(), isTrue);
      gateway.canOpenSettings = false;
      expect(await SmartPermission.openSettings(), isFalse);
      expect(gateway.openSettingsCalls, 2);
      expect(gateway.waitForSettingsReturnCalls, 0);
    });
  });
}
