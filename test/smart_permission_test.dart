import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_permission/smart_permission.dart';

/// Test double driving the flows without platform channels.
class FakeGateway implements SmartPermissionGateway {
  final Map<Permission, PermissionStatus> statuses =
      <Permission, PermissionStatus>{};

  /// Statuses returned by successive request() calls, per permission.
  /// When exhausted (or absent), the current status is returned.
  final Map<Permission, List<PermissionStatus>> requestQueue =
      <Permission, List<PermissionStatus>>{};

  /// Applied to [statuses] when the user "returns from settings".
  final Map<Permission, PermissionStatus> afterSettings =
      <Permission, PermissionStatus>{};

  bool openSettingsResult = true;
  int openSettingsCalls = 0;
  int waitForReturnCalls = 0;
  bool throwOnStatus = false;
  bool throwOnRequest = false;

  @override
  Future<PermissionStatus> status(Permission permission) async {
    if (throwOnStatus) throw StateError('status failure');
    return statuses[permission] ?? PermissionStatus.denied;
  }

  @override
  Future<PermissionStatus> request(Permission permission) async {
    if (throwOnRequest) throw StateError('request failure');
    final queue = requestQueue[permission];
    final next = (queue != null && queue.isNotEmpty)
        ? queue.removeAt(0)
        : (statuses[permission] ?? PermissionStatus.denied);
    statuses[permission] = next;
    return next;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestMultiple(
      List<Permission> permissions) async {
    final out = <Permission, PermissionStatus>{};
    for (final p in permissions) {
      out[p] = await request(p);
    }
    return out;
  }

  @override
  Future<bool> openAppSettings() async {
    openSettingsCalls++;
    return openSettingsResult;
  }

  @override
  Future<void> waitForSettingsReturn() async {
    waitForReturnCalls++;
    statuses.addAll(afterSettings);
  }
}

Future<BuildContext> pumpHost(WidgetTester tester) async {
  late BuildContext hostContext;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            hostContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return hostContext;
}

void main() {
  late FakeGateway gateway;
  late InMemoryPermissionAnalyticsTracker analytics;

  setUp(() {
    SmartPermission.config.resetToDefaults();
    gateway = FakeGateway();
    analytics = InMemoryPermissionAnalyticsTracker();
    SmartPermission.config
      ..gateway = gateway
      ..analytics = analytics;
  });

  tearDown(() {
    SmartPermission.config.resetToDefaults();
  });

  group('single permission', () {
    testWidgets('already granted returns granted without dialogs',
        (tester) async {
      final ctx = await pumpHost(tester);
      gateway.statuses[Permission.camera] = PermissionStatus.granted;

      final result = await SmartPermission.requestResult(
          context: ctx, permission: Permission.camera);

      expect(result, SmartPermissionResult.granted);
      expect(analytics.requestedCounts, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('granted on first native prompt', (tester) async {
      final ctx = await pumpHost(tester);
      gateway.requestQueue[Permission.camera] = [PermissionStatus.granted];

      final result = await SmartPermission.requestResult(
          context: ctx, permission: Permission.camera);

      expect(result, SmartPermissionResult.granted);
      expect(analytics.requestedCounts[Permission.camera], 1);
      expect(analytics.grantedCounts[Permission.camera], 1);
    });

    testWidgets('denied then allowed via rationale dialog', (tester) async {
      final ctx = await pumpHost(tester);
      gateway.requestQueue[Permission.camera] = [
        PermissionStatus.denied,
        PermissionStatus.granted,
      ];

      final future = SmartPermission.requestResult(
          context: ctx, permission: Permission.camera);
      await tester.pumpAndSettle();

      // Built-in title and description for camera.
      expect(find.text('Camera Access'), findsOneWidget);
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(await future, SmartPermissionResult.granted);
      expect(analytics.grantedCounts[Permission.camera], 1);
    });

    testWidgets('denied and user declines rationale', (tester) async {
      final ctx = await pumpHost(tester);
      gateway.requestQueue[Permission.camera] = [PermissionStatus.denied];

      final future = SmartPermission.requestResult(
          context: ctx, permission: Permission.camera);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(await future, SmartPermissionResult.denied);
      expect(analytics.deniedCounts[Permission.camera], 1);
    });

    testWidgets('permanently denied: settings flow re-checks after return',
        (tester) async {
      final ctx = await pumpHost(tester);
      gateway.requestQueue[Permission.camera] = [
        PermissionStatus.permanentlyDenied,
      ];
      gateway.afterSettings[Permission.camera] = PermissionStatus.granted;

      final future = SmartPermission.requestResult(
          context: ctx, permission: Permission.camera);
      await tester.pumpAndSettle();

      expect(find.text('Open Settings'), findsOneWidget);
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(await future, SmartPermissionResult.granted);
      expect(gateway.openSettingsCalls, 1);
      expect(gateway.waitForReturnCalls, 1,
          reason: 'must wait for the user to return before re-checking');
    });

    testWidgets('permanently denied: settings cannot open shows fallback',
        (tester) async {
      final ctx = await pumpHost(tester);
      gateway.requestQueue[Permission.camera] = [
        PermissionStatus.permanentlyDenied,
      ];
      gateway.openSettingsResult = false;

      final future = SmartPermission.requestResult(
          context: ctx, permission: Permission.camera);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Open settings manually'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(await future, SmartPermissionResult.permanentlyDenied);
    });

    testWidgets('restricted shows informational dialog', (tester) async {
      final ctx = await pumpHost(tester);
      gateway.requestQueue[Permission.camera] = [PermissionStatus.restricted];

      final future = SmartPermission.requestResult(
          context: ctx, permission: Permission.camera);
      await tester.pumpAndSettle();

      expect(find.textContaining('restricted on this device'), findsOneWidget);
      // No settings offer: settings can't fix restricted permissions.
      expect(find.text('Open Settings'), findsNothing);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(await future, SmartPermissionResult.restricted);
      expect(analytics.restrictedCounts[Permission.camera], 1);
      expect(gateway.openSettingsCalls, 0);
    });

    testWidgets('rationale-first explains before the native prompt',
        (tester) async {
      final ctx = await pumpHost(tester);
      gateway.requestQueue[Permission.camera] = [PermissionStatus.granted];

      final future = SmartPermission.requestResult(
        context: ctx,
        permission: Permission.camera,
        showRationaleFirst: true,
      );
      await tester.pumpAndSettle();

      // Dialog appears before request() has been called.
      expect(find.text('Camera Access'), findsOneWidget);
      expect(
          gateway.statuses[Permission.camera], isNot(PermissionStatus.granted));
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(await future, SmartPermissionResult.granted);
    });

    test('platform error surfaces as error result and onError', () async {
      gateway.throwOnStatus = true;
      Object? seen;
      SmartPermission.config.onError = (e, st) => seen = e;

      final result =
          await SmartPermission.requestResult(permission: Permission.camera);

      expect(result, SmartPermissionResult.error);
      expect(seen, isA<StateError>());
    });

    test('no context and no navigatorKey: native-only flow', () async {
      gateway.requestQueue[Permission.camera] = [PermissionStatus.denied];

      final result =
          await SmartPermission.requestResult(permission: Permission.camera);

      expect(result, SmartPermissionResult.denied);
      expect(analytics.deniedCounts[Permission.camera], 1);
    });

    testWidgets('navigatorKey enables dialogs without a context',
        (tester) async {
      final key = GlobalKey<NavigatorState>();
      SmartPermission.config.navigatorKey = key;
      await tester.pumpWidget(MaterialApp(
        navigatorKey: key,
        home: const Scaffold(body: SizedBox.shrink()),
      ));
      gateway.requestQueue[Permission.camera] = [PermissionStatus.denied];

      final future =
          SmartPermission.requestResult(permission: Permission.camera);
      await tester.pumpAndSettle();

      expect(find.text('Camera Access'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(await future, SmartPermissionResult.denied);
    });
  });

  group('multiple permissions', () {
    testWidgets('batch flow with one combined rationale dialog',
        (tester) async {
      final ctx = await pumpHost(tester);
      gateway.statuses[Permission.camera] = PermissionStatus.granted;
      gateway.requestQueue[Permission.microphone] = [PermissionStatus.granted];
      gateway.requestQueue[Permission.location] = [PermissionStatus.denied];

      final future = SmartPermission.requestMultipleResults(
        context: ctx,
        permissions: [
          Permission.camera,
          Permission.microphone,
          Permission.location,
        ],
      );
      await tester.pumpAndSettle();

      // One dialog naming only the still-denied permission.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Location Access'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      final results = await future;
      expect(results[Permission.camera], SmartPermissionResult.granted);
      expect(results[Permission.microphone], SmartPermissionResult.granted);
      expect(results[Permission.location], SmartPermissionResult.denied);
    });

    testWidgets('combined retry grants remaining permissions', (tester) async {
      final ctx = await pumpHost(tester);
      gateway.requestQueue[Permission.location] = [
        PermissionStatus.denied,
        PermissionStatus.granted,
      ];

      final future = SmartPermission.requestMultipleResults(
        context: ctx,
        permissions: [Permission.location],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      final results = await future;
      expect(results[Permission.location], SmartPermissionResult.granted);
    });

    testWidgets('permanently denied group gets one settings dialog',
        (tester) async {
      final ctx = await pumpHost(tester);
      gateway.requestQueue[Permission.camera] = [
        PermissionStatus.permanentlyDenied,
      ];
      gateway.requestQueue[Permission.microphone] = [
        PermissionStatus.permanentlyDenied,
      ];
      gateway.afterSettings[Permission.camera] = PermissionStatus.granted;
      gateway.afterSettings[Permission.microphone] = PermissionStatus.granted;

      final future = SmartPermission.requestMultipleResults(
        context: ctx,
        permissions: [Permission.camera, Permission.microphone],
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      final results = await future;
      expect(gateway.openSettingsCalls, 1);
      expect(results[Permission.camera], SmartPermissionResult.granted);
      expect(results[Permission.microphone], SmartPermissionResult.granted);
    });
  });

  group('backward-compatible bool API', () {
    testWidgets('request returns true for limited access', (tester) async {
      final ctx = await pumpHost(tester);
      gateway.requestQueue[Permission.photos] = [PermissionStatus.limited];

      final ok =
          await SmartPermission.request(ctx, permission: Permission.photos);

      expect(ok, isTrue);
    });

    testWidgets('requestMultiple returns bool map', (tester) async {
      final ctx = await pumpHost(tester);
      gateway.statuses[Permission.camera] = PermissionStatus.granted;
      gateway.requestQueue[Permission.microphone] = [PermissionStatus.denied];

      final future = SmartPermission.requestMultiple(ctx,
          permissions: [Permission.camera, Permission.microphone]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      final results = await future;
      expect(results, {Permission.camera: true, Permission.microphone: false});
    });
  });

  group('localization', () {
    testWidgets('custom strings are used in dialogs', (tester) async {
      SmartPermission.config.strings = const SmartPermissionStrings(
        allow: 'Autoriser',
        notNow: 'Plus tard',
      );
      final ctx = await pumpHost(tester);
      gateway.requestQueue[Permission.camera] = [PermissionStatus.denied];

      final future = SmartPermission.requestResult(
          context: ctx, permission: Permission.camera);
      await tester.pumpAndSettle();

      expect(find.text('Autoriser'), findsOneWidget);
      await tester.tap(find.text('Plus tard'));
      await tester.pumpAndSettle();

      expect(await future, SmartPermissionResult.denied);
    });
  });

  group('provisional and limited statuses', () {
    test('provisional counts as canProceed', () async {
      gateway.requestQueue[Permission.notification] = [
        PermissionStatus.provisional,
      ];

      final result = await SmartPermission.requestResult(
          permission: Permission.notification);

      expect(result, SmartPermissionResult.provisional);
      expect(result.canProceed, isTrue);
      expect(result.isGranted, isFalse);
    });
  });
}
