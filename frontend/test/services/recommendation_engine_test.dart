import 'package:flutter_test/flutter_test.dart';
import 'package:autism_learning_assistant/models/activity_attempt.dart';
import 'package:autism_learning_assistant/models/activity_result.dart';
import 'package:autism_learning_assistant/services/performance_analyzer.dart';
import 'package:autism_learning_assistant/services/recommendation_engine.dart';

ActivityResult r(String category, double accuracy, int day) {
  const total = 10;
  final correct = (accuracy / 10).round();
  return ActivityResult(
    childId: 1,
    activityId: 1,
    category: category,
    difficulty: 1,
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
  test('recommends a weak category first', () {
    final analysis = const PerformanceAnalyzer().analyze([
      r('numbers', 40, 1),
      r('numbers', 50, 2),
      r('colors', 90, 3),
    ]);
    final recommendations = const RecommendationEngine().recommend(
      analysis: analysis,
    );
    expect(recommendations.first.category, 'numbers');
    expect(recommendations.first.reason, contains('more practice'));
  });

  test('recommends improving skills', () {
    final analysis = const PerformanceAnalyzer().analyze([
      r('numbers', 50, 1),
      r('numbers', 70, 2),
    ]);
    final recommendations = const RecommendationEngine().recommend(
      analysis: analysis,
    );
    expect(recommendations.first.category, 'numbers');
    expect(recommendations.first.reason, contains('improving'));
  });

  test('returns local recommendations when there is no history', () {
    final analysis = const PerformanceAnalyzer().analyze([]);
    final recommendations = const RecommendationEngine().recommend(
      analysis: analysis,
    );
    expect(recommendations, isNotEmpty);
    expect(recommendations.first.difficulty, 'easy');
  });
}
