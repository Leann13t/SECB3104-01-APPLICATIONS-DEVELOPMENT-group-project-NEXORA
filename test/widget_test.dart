import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:nexora/main.dart';
import 'package:nexora/screens/map/map_screen.dart';

void main() {
  testWidgets('App smoke test - verifies SplashPage renders', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify that the LoraGuide brand title and Get Started button render
    expect(find.text('LoraGuide'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Map screen displays the live-capable OpenStreetMap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MapScreen()));
    await tester.pump();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
