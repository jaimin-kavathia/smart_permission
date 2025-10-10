// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_permission/smart_permission.dart';

import 'package:smart_permission_example/main.dart';

void main() {
  testWidgets('Example app renders and toggles theme & dialog style', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    // App bar present
    expect(find.text('smart_permission example'), findsOneWidget);

    // Toggle theme
    await tester.tap(find.byTooltip('Toggle Dark Theme').hitTestable());
    await tester.pumpAndSettle();

    // Change dialog style via dropdown
    await tester.tap(find.byType(DropdownButton<PermissionDialogStyle>));
    await tester.pumpAndSettle();
    expect(find.text('Material'), findsWidgets);
  });
}
