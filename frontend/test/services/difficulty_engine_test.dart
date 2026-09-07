import 'package:flutter_test/flutter_test.dart';
import 'package:autism_learning_assistant/models/activity_attempt.dart';
import 'package:autism_learning_assistant/models/activity_result.dart';
import 'package:autism_learning_assistant/services/difficulty_engine.dart';
import 'package:autism_learning_assistant/services/performance_analyzer.dart';

ActivityResult r(String category, double accuracy, int difficulty, int day) {
  final total = 10;
  final correct = (accuracy / 10).round();
  return ActivityResult(
    childId: 1,
    activityId: 1,
    category: category,
    difficulty: difficulty,
    attempts: List.generate(
      total,
      (i) => ActivityAttempt(
        childId: 1,
        activityId: 1,
        questionIndex: i,
        isCorrect: i < correct,
        responseTime: const Duration(seconds: 1),
        timestamp: DateTime(2026, 8, day),
      ),
    ),
    score: correct,
    totalQuestions: total,
    correctAnswers: correct,
    wrongAnswers: total - correct,
    totalAttempts: total,
    accuracy: accuracy,
    averageResponseTime: 1000,
    isCompleted: true,
    timestamp: DateTime(2026, 8, day),
  );
}

void main() {
  const analyzer = PerformanceAnalyzer();
  const engine = DifficultyEngine();

  test('increases difficulty after strong performance', () {
    final analysis = analyzer.analyze([
      r('numbers', 90, 1, 1),
      r('numbers', 90, 1, 2),
    ]);
    final decision = engine.chooseDifficulty(
      category: 'numbers',
      currentDifficulty: 'easy',
      analysis: analysis,
    );
    expect(decision.difficulty, 'medium');
    expect(decision.adjustment, DifficultyAdjustment.increase);
  });

  test('keeps difficulty for moderate performance', () {
    final analysis = analyzer.analyze([
      r('numbers', 70, 2, 1),
      r('numbers', 70, 2, 2),
    ]);
    final decision = engine.chooseDifficulty(
      category: 'numbers',
      currentDifficulty: 'medium',
      analysis: analysis,
    );
    expect(decision.difficulty, 'medium');
    expect(decision.adjustment, DifficultyAdjustment.keep);
  });

  test('reduces difficulty after weak performance', () {
    final analysis = analyzer.analyze([
      r('numbers', 40, 2, 1),
      r('numbers', 50, 2, 2),
    ]);
    final decision = engine.chooseDifficulty(
      category: 'numbers',
      currentDifficulty: 'medium',
      analysis: analysis,
    );
    expect(decision.difficulty, 'easy');
    expect(decision.adjustment, DifficultyAdjustment.decrease);
  });

  test('does not exceed hard or go below easy', () {
    final strong = analyzer.analyze([
      r('numbers', 100, 3, 1),
      r('numbers', 100, 3, 2),
    ]);
    final weak = analyzer.analyze([
      r('numbers', 20, 1, 1),
      r('numbers', 30, 1, 2),
    ]);
    expect(
      engine
          .chooseDifficulty(
            category: 'numbers',
            currentDifficulty: 'hard',
            analysis: strong,
          )
          .difficulty,
      'hard',
    );
    expect(
      engine
          .chooseDifficulty(
            category: 'numbers',
            currentDifficulty: 'easy',
            analysis: weak,
          )
          .difficulty,
      'easy',
    );
  });
}
