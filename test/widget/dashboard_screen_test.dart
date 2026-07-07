import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signal_scope/src/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets('renders dashboard shell', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen(useDemoOverride: true)));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('SignalScope'), findsOneWidget);
    expect(find.text('Diagnostico inicial'), findsOneWidget);
    expect(find.textContaining('BLE'), findsWidgets);
  });
}
