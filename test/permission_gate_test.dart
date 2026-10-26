import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_permission/smart_permission.dart';
import 'package:smart_permission/testing.dart';

const _content = Text('camera content');

Future<void> pumpGate(WidgetTester tester, PermissionGate gate) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: gate)));
  await tester.pumpAndSettle();
}

PermissionGate cameraGate({
  PermissionGateFallbackBuilder? fallbackBuilder,
  bool requestOnMount = false,
  ValueChanged<SmartPermissionResult>? onChanged,
}) {
  return PermissionGate(
    permission: Permission.camera,
    builder: (_) => _content,
    fallbackBuilder: fallbackBuilder,
    requestOnMount: requestOnMount,
    onChanged: onChanged,
    style: PermissionDialogStyle.material,
  );
}

void main() {
  late FakeSmartPermissionGateway gateway;

  setUp(() {
    SmartPermission.config.resetToDefaults();
    gateway = FakeSmartPermissionGateway();
    SmartPermission.config.gateway = gateway;
  });

  tearDown(() => SmartPermission.config.resetToDefaults());

  testWidgets('shows content when already granted', (tester) async {
    gateway.statuses[Permission.camera] = PermissionStatus.granted;

    await pumpGate(tester, cameraGate());

    expect(find.text('camera content'), findsOneWidget);
    expect(gateway.requestedPermissions, isEmpty);
  });

  testWidgets('limited access also unlocks the content', (tester) async {
    gateway.statuses[Permission.camera] = PermissionStatus.limited;

    await pumpGate(tester, cameraGate());

    expect(find.text('camera content'), findsOneWidget);
  });

  testWidgets('denied: default fallback requests on tap', (tester) async {
    final changes = <SmartPermissionResult>[];
    gateway.requestResults[Permission.camera] = [PermissionStatus.granted];

    await pumpGate(tester, cameraGate(onChanged: changes.add));

    expect(find.text('camera content'), findsNothing);
    expect(find.text('Camera Access'), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    expect(find.text('camera content'), findsOneWidget);
    expect(gateway.requestedPermissions, [Permission.camera]);
    expect(
        changes, [SmartPermissionResult.denied, SmartPermissionResult.granted]);
  });

  testWidgets('permanently denied: opens settings, re-checks on resume',
      (tester) async {
    gateway.statuses[Permission.camera] = PermissionStatus.permanentlyDenied;

    await pumpGate(tester, cameraGate());

    expect(
        find.textContaining('enable it in the app settings'), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(gateway.openSettingsCalls, 1);
    expect(gateway.requestedPermissions, isEmpty,
        reason: 'a request cannot help a permanently denied permission');
    expect(find.byType(AlertDialog), findsNothing);

    // The user enables the camera in settings and comes back.
    gateway.statuses[Permission.camera] = PermissionStatus.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('camera content'), findsOneWidget);
  });

  testWidgets('restricted: explains and offers no button', (tester) async {
    gateway.statuses[Permission.camera] = PermissionStatus.restricted;

    await pumpGate(tester, cameraGate());

    expect(find.textContaining('restricted on this device'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('custom fallback gets the result and a request callback',
      (tester) async {
    gateway.requestResults[Permission.camera] = [PermissionStatus.granted];

    await pumpGate(
      tester,
      cameraGate(
        fallbackBuilder: (context, result, request) => TextButton(
          onPressed: request,
          child: Text('custom ${result.name}'),
        ),
      ),
    );

    expect(find.text('custom denied'), findsOneWidget);
    await tester.tap(find.text('custom denied'));
    await tester.pumpAndSettle();

    expect(find.text('camera content'), findsOneWidget);
  });

  testWidgets('requestOnMount starts the flow without a tap', (tester) async {
    gateway.requestResults[Permission.camera] = [PermissionStatus.granted];

    await pumpGate(tester, cameraGate(requestOnMount: true));

    expect(gateway.requestedPermissions, [Permission.camera]);
    expect(find.text('camera content'), findsOneWidget);
  });

  testWidgets('requestOnMount does not request when already granted',
      (tester) async {
    gateway.statuses[Permission.camera] = PermissionStatus.granted;

    await pumpGate(tester, cameraGate(requestOnMount: true));

    expect(gateway.requestedPermissions, isEmpty);
    expect(find.text('camera content'), findsOneWidget);
  });

  testWidgets('re-checks when the guarded permission changes', (tester) async {
    gateway.statuses
      ..[Permission.camera] = PermissionStatus.denied
      ..[Permission.microphone] = PermissionStatus.granted;

    await pumpGate(tester, cameraGate());
    expect(find.text('camera content'), findsNothing);

    await pumpGate(
      tester,
      PermissionGate(
        permission: Permission.microphone,
        builder: (_) => const Text('mic content'),
      ),
    );

    expect(find.text('mic content'), findsOneWidget);
  });
}
