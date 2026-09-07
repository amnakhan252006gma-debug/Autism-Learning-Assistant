import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autism_learning_assistant/models/activity_question.dart';
import 'package:autism_learning_assistant/screens/activity_screen.dart';
import 'package:autism_learning_assistant/services/activity_result_repository.dart';
import 'package:autism_learning_assistant/services/mock_activity_data.dart';

const _testColor = Color(0xFF64B5F6);

Future<void> _pumpActivity(
  WidgetTester tester, {
  String title = 'Colors',
  List<ActivityQuestion> questions = MockActivityData.colorsQuestions,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ActivityScreen(
        title: title,
        color: _testColor,
        questions: questions,
        childId: 1,
        activityId: 1,
      ),
    ),
  );
}

Future<void> _tapChoice(WidgetTester tester, int index) async {
  await tester.ensureVisible(find.byKey(ValueKey('choice_$index')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('choice_$index')));
  await tester.pump();
}

void main() {
  testWidgets('loads the first question with answer choices', (tester) async {
    await _pumpActivity(tester);

    expect(find.text('Which one is RED?'), findsOneWidget);
    expect(find.byKey(const ValueKey('choice_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('choice_3')), findsOneWidget);
    expect(find.text('Tap your answer'), findsOneWidget);
  });

  testWidgets('correct answer shows positive feedback and advances', (
    tester,
  ) async {
    await _pumpActivity(tester);

    // Red (choice 0) is the correct answer for the first question.
    await _tapChoice(tester, 0);
    expect(find.text('Great job!'), findsOneWidget);

    // Wait for the auto-advance timer to fire.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Which one is BLUE?'), findsOneWidget);
  });

  testWidgets(
    'wrong answer shows gentle retry feedback and stays on question',
    (tester) async {
      await _pumpActivity(tester);

      // Blue (choice 1) is wrong for the RED question.
      await _tapChoice(tester, 1);
      expect(find.text('Try again! You can do it!'), findsOneWidget);
      expect(find.text('Which one is RED?'), findsOneWidget);

      // No auto-advance after a wrong answer.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Which one is RED?'), findsOneWidget);
    },
  );

  testWidgets('score counts first-attempt correct answers only', (
    tester,
  ) async {
    const questions = [
      ActivityQuestion(
        prompt: 'Pick A',
        choices: [
          ActivityChoice.text('A'),
          ActivityChoice.text('B'),
          ActivityChoice.text('C'),
        ],
        correctIndex: 0,
      ),
      ActivityQuestion(
        prompt: 'Pick B',
        choices: [
          ActivityChoice.text('A'),
          ActivityChoice.text('B'),
          ActivityChoice.text('C'),
        ],
        correctIndex: 1,
      ),
    ];
    await _pumpActivity(tester, title: 'Test', questions: questions);

    // Question 1: one wrong attempt, then correct -> no score point.
    await _tapChoice(tester, 1);
    await _tapChoice(tester, 0);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.text('Pick B'), findsOneWidget);

    // Question 2: correct on the first attempt -> one score point.
    await _tapChoice(tester, 1);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    // Result: 1 of 2 correct on first attempt.
    expect(find.text('Good try!'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('completing every question first-try shows a perfect result', (
    tester,
  ) async {
    await _pumpActivity(
      tester,
      title: 'Numbers',
      questions: MockActivityData.numbersQuestions,
    );

    for (final question in MockActivityData.numbersQuestions) {
      await _tapChoice(tester, question.correctIndex);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
    }

    expect(find.text('Perfect!'), findsOneWidget);
    expect(find.text('5 / 5'), findsOneWidget);

    // Play Again restarts the activity from the first question.
    await tester.tap(find.text('Play Again'));
    await tester.pumpAndSettle();
    expect(find.text('Which number is 3?'), findsOneWidget);
  });

  testWidgets('completing activity saves result to repository', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = ActivityResultRepository();
    await repo.initialise();

    const questions = [
      ActivityQuestion(
        prompt: 'Pick A',
        choices: [ActivityChoice.text('A'), ActivityChoice.text('B')],
        correctIndex: 0,
      ),
      ActivityQuestion(
        prompt: 'Pick B',
        choices: [ActivityChoice.text('A'), ActivityChoice.text('B')],
        correctIndex: 1,
      ),
    ];

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ActivityScreen(
          title: 'Test',
          color: _testColor,
          questions: questions,
          childId: 1,
          activityId: 1,
        ),
      ),
    );

    // Answer both questions correctly on first attempt.
    await _tapChoice(tester, 0);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    await _tapChoice(tester, 1);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    // Result screen should appear.
    expect(find.text('Perfect!'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);

    // Verify the result was persisted.
    final all = await repo.getAllResults();
    expect(all.length, 1);
    expect(all.first.score, 2);
    expect(all.first.totalQuestions, 2);
    expect(all.first.correctAnswers, 2);
    expect(all.first.wrongAnswers, 0);
    expect(all.first.isCompleted, true);
  });
}
