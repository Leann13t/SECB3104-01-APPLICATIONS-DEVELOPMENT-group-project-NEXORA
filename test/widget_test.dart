import 'package:flutter_test/flutter_test.dart';

import 'package:nexora/main.dart';

void main() {
  testWidgets('App smoke test - verifies SplashPage renders', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify that the LoraGuide brand title and Get Started button render
    expect(find.text('LoraGuide'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
