import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/app.dart';

void main() {
  testWidgets('CRM app renders AppBar with menu and navigates to pages', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CRMApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify AppBar and Camera Capture title are present
    expect(find.text('Camera Capture'), findsOneWidget);

    // Verify Hamburger Menu icon is present
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

    // Verify either Camera viewfinder or Permission request view is present
    expect(
      find.byIcon(Icons.camera_alt).evaluate().isNotEmpty ||
          find.text('Camera Access Required').evaluate().isNotEmpty,
      isTrue,
    );

    // Open the drawer via the menu button
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Drawer navigation items are visible
    expect(find.text('AnjaniCRM'), findsOneWidget);
    expect(find.text('Customer Directory'), findsOneWidget);
    expect(find.text('Create Customer'), findsOneWidget);

    // Tap 'Customer Directory' to navigate
    await tester.tap(find.text('Customer Directory'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify AppBar title updated to Customer Directory
    expect(find.text('Customer Directory'), findsOneWidget);
  });
}
