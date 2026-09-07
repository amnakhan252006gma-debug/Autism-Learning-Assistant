import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autism_learning_assistant/screens/activity_result_screen.dart';
import 'package:autism_learning_assistant/screens/activity_screen.dart';
import 'package:autism_learning_assistant/screens/home_screen.dart';
import 'package:autism_learning_assistant/screens/progress_screen.dart';
import 'package:autism_learning_assistant/services/activity_result_repository.dart';
import 'package:autism_learning_assistant/services/mock_activity_data.dart';
import 'package:autism_learning_assistant/theme/app_theme.dart';

/// End-to-end widget test for the animated learning journey:
/// Home → recommended activity → answers + feedback → next question →
/// result → back home → progress → recommended again.
void main() {
  setUpAll(() {
    // Keep widget tests hermetic: never fetch Google Fonts over HTTP.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'full journey: home → recommended activity → feedback → result → progress',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await ActivityResultRepository.instance.initialise();

      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: const HomeScreen(childId: 1, childName: 'Alex'),
        ),
      );
      await tester.pumpAndSettle();

      // ── Home shows the recommendation and the learning space ──────
      expect(find.text('Recommended for you'), findsOneWidget);
      expect(find.text('Your learning space'), findsOneWidget);
      expect(find.text('Learn'), findsOneWidget);

      // Open the recommended activity (Colors with the mock data).
      await tester.tap(find.text('Recommended for you'));
      await tester.pumpAndSettle();
      expect(find.byType(ActivityScreen), findsOneWidget);

      // ── Question 1: wrong answer → gentle retry feedback ─────────
      final questions = MockActivityData.colorsQuestions;
      final first = questions.first;
      final wrongIndex = (first.correctIndex + 1) % first.choices.length;
      await _tapChoice(tester, wrongIndex);
      expect(find.text('Try again! You can do it!'), findsOneWidget);
      expect(find.text(first.prompt), findsOneWidget); // stays on question

      // ── Correct answer → positive feedback → next question ───────
      await _tapChoice(tester, first.correctIndex);
      expect(find.text('Great job!'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect(find.text(questions[1].prompt), findsOneWidget);

      // ── Remaining questions answered on the first try ─────────────
      for (final question in questions.skip(1)) {
        await _tapChoice(tester, question.correctIndex);
        await tester.pump(const Duration(milliseconds: 1600));
        await tester.pumpAndSettle();
      }

      expect(find.byType(ActivityResultScreen), findsOneWidget);
      // First question needed a retry, so only four of five scored.
      expect(find.text('Great job!'), findsOneWidget);
      expect(find.text('4 / 5'), findsOneWidget);

      // ── Back home, then into the progress screen ──────────────────
      await tester.tap(find.text('All Done'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(find.text('Your progress'));
      await tester.pumpAndSettle();
      expect(find.byType(ProgressScreen), findsOneWidget);
      expect(find.text('Overall progress'), findsOneWidget);
      expect(find.text('1 activities'), findsOneWidget);

      // ── Back home: the recommendation is ready for another round ──
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Recommended for you'), findsOneWidget);
    },
  );
}

Future<void> _tapChoice(WidgetTester tester, int index) async {
  await tester.ensureVisible(find.byKey(ValueKey('choice_$index')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('choice_$index')));
  await tester.pump();
}
