import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/mood/presentation/views/add_mood_screen.dart';

void main() {
  testWidgets('Tap mood icon test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddMoodScreen()),
                  );
                },
                child: const Text('Open'),
              );
            }
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Now on AddMoodScreen
    final firstIcon = find.byType(GestureDetector).first;
    await tester.tap(firstIcon);
    
    // Pump frames to catch any animation exceptions
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  });
}
