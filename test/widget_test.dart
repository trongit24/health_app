// Basic smoke test for SoulFlow app.

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/main.dart';
import 'package:health_app/features/auth/presentation/views/onboarding_screen.dart';

void main() {
  testWidgets('SoulFlow app renders correctly', (WidgetTester tester) async {
    // Build SoulFlow app and trigger a frame.
    await tester.pumpWidget(const SoulFlowApp(initialScreen: OnboardingScreen()));

    // Verify the SoulFlow title text appears
    expect(find.text('SoulFlow'), findsOneWidget);
  });
}
