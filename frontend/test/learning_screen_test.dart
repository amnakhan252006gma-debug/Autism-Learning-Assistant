import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autism_learning_assistant/screens/activity_screen.dart';
import 'package:autism_learning_assistant/screens/learning_screen.dart';

void main() {
  testWidgets('all four activities can be opened from the Learning screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: LearningScreen(childId: 1)),
    );
    // Let staggered entrance animations (Future.delayed + 450ms tween)
    // fully complete before interacting.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    const firstPrompts = {
      'Colors': 'Which one is RED?',
      'Shapes': 'Which one is a CIRCLE?',
      'Numbers': 'Which number is 3?',
      'Words': 'Which word matches the picture?',
    };

    for (final title in firstPrompts.keys) {
      // Tap the activity card by its ValueKey for a reliable hit test.
      await tester.tap(find.byKey(ValueKey('activity_$title')));
      await tester.pumpAndSettle();

      // The activity screen opens and shows its first question.
      expect(find.byType(ActivityScreen), findsOneWidget);
      expect(find.text(firstPrompts[title]!), findsOneWidget);
      expect(find.byKey(const ValueKey('choice_0')), findsOneWidget);

      // Go back to the Learning screen.
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(LearningScreen), findsOneWidget);
    }
  });
}
