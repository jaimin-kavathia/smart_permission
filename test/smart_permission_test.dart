import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_permission/smart_permission.dart';
import 'package:smart_permission/testing.dart';

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
  late FakeSmartPermissionGateway gateway;
  late InMemoryPermissionAnalyticsTracker analytics;

  setUp(() {
    SmartPermission.config.resetToDefaults();
    gateway = FakeSmartPermissionGateway();
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
      gateway.requestResults[Permission.camera] = [PermissionStatus.granted];

      final result = await SmartPermission.requestResult(
          context: ctx, permission: Permission.camera);

      expect(result, SmartPermissionResult.granted);
      expect(analytics.requestedCounts[Permission.camera], 1);
      expect(analytics.grantedCounts[Permission.camera], 1);
    });

    testWidgets('denied then allowed via rationale dialog', (tester) async {
      final ctx = await pumpHost(tester);
      gateway.requestResults[Permission.camera] = [
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
      gateway.requestResults[Permission.camera] = [PermissionStatus.denied];

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
      gateway.requestResults[Permission.camera] = [
        PermissionStatus.permanentlyDenied,
      ];
      gateway.statusesAfterSettings[Permission.camera] =
          PermissionStatus.granted;

      final future = SmartPermission.requestResult(
          context: ctx, permission: Permission.camera);
      await tester.pumpAndSettle();

      expect(find.text('Open Settings'), findsOneWidget);
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(await future, SmartPermissionResult.granted);
      expect(gateway.openSettingsCalls, 1);
      expect(gateway.waitForSettingsReturnCalls, 1,
          reason: 'must wait for the user to return before re-checking');
    });

    testWidgets('permanently denied: settings cannot open shows fallback',
        (tester) async {
      final ctx = await pumpHost(tester);
      gateway.requestResults[Permission.camera] = [
        PermissionStatus.permanentlyDenied,
      ];
      gateway.canOpenSettings = false;

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
      gateway.requestResults[Permission.camera] = [PermissionStatus.restricted];

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
      gateway.requestResults[Permission.camera] = [PermissionStatus.granted];

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

    testWidgets(
        'rationale-first is skipped once Android reported permanent denial',
        (tester) async {
      final ctx = await pumpHost(tester);
      gateway
        ..androidStatusSemantics = true
        ..requestResults[Permission.camera] = [
          PermissionStatus.permanentlyDenied,
          PermissionStatus.permanentlyDenied,
        ];

      // First call: status says `denied`, so the rationale is shown, then
      // the request reveals the permanent denial.
      var future = SmartPermission.requestResult(
        context: ctx,
        permission: Permission.camera,
        showRationaleFirst: true,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();
      expect(find.text('Open Settings'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await future, SmartPermissionResult.permanentlyDenied);

      // Second call: straight to the settings dialog, no rationale first.
      future = SmartPermission.requestResult(
        context: ctx,
        permission: Permission.camera,
        showRationaleFirst: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('Allow'), findsNothing);
      expect(find.text('Open Settings'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await future, SmartPermissionResult.permanentlyDenied);
    });

    testWidgets('rationale-first returns after the user re-enables asking',
        (tester) async {
      final ctx = await pumpHost(tester);
      gateway
        ..androidStatusSemantics = true
        ..requestResults[Permission.camera] = [
          PermissionStatus.permanentlyDenied,
          PermissionStatus.denied,
        ];

      // Learn that camera is blocked (no rationale, no dialogs: no context).
      expect(await SmartPermission.requestResult(permission: Permission.camera),
          SmartPermissionResult.permanentlyDenied);
      // The user switches it back to "Ask every time"; the next native
      // request shows the OS prompt and the user denies it normally.
      gateway.statuses[Permission.camera] = PermissionStatus.denied;
      expect(await SmartPermission.requestResult(permission: Permission.camera),
          SmartPermissionResult.denied);

      final future = SmartPermission.requestResult(
        context: ctx,
        permission: Permission.camera,
        showRationaleFirst: true,
      );
      await tester.pumpAndSettle();
      expect(find.text('Allow'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(await future, SmartPermissionResult.denied);
    });

    test('platform error surfaces as error result and onError', () async {
      gateway.statusError = StateError('status failure');
      Object? seen;
      SmartPermission.config.onError = (e, st) => seen = e;

      final result =
          await SmartPermission.requestResult(permission: Permission.camera);

      expect(result, SmartPermissionResult.error);
      expect(seen, isA<StateError>());
    });

    test('no context and no navigatorKey: native-only flow', () async {
      gateway.requestResults[Permission.camera] = [PermissionStatus.denied];

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
      gateway.requestResults[Permission.camera] = [PermissionStatus.denied];

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
      gateway.requestResults[Permission.microphone] = [
        PermissionStatus.granted
      ];
      gateway.requestResults[Permission.location] = [PermissionStatus.denied];

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
      gateway.requestResults[Permission.location] = [
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
      gateway.requestResults[Permission.camera] = [
        PermissionStatus.permanentlyDenied,
      ];
      gateway.requestResults[Permission.microphone] = [
        PermissionStatus.permanentlyDenied,
      ];
      gateway.statusesAfterSettings[Permission.camera] =
          PermissionStatus.granted;
      gateway.statusesAfterSettings[Permission.microphone] =
          PermissionStatus.granted;

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
      gateway.requestResults[Permission.photos] = [PermissionStatus.limited];

      final ok =
          await SmartPermission.request(ctx, permission: Permission.photos);

      expect(ok, isTrue);
    });

    testWidgets('requestMultiple returns bool map', (tester) async {
      final ctx = await pumpHost(tester);
      gateway.statuses[Permission.camera] = PermissionStatus.granted;
      gateway.requestResults[Permission.microphone] = [PermissionStatus.denied];

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
      gateway.requestResults[Permission.camera] = [PermissionStatus.denied];

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
      gateway.requestResults[Permission.notification] = [
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
