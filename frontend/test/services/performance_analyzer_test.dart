import 'package:flutter_test/flutter_test.dart';
import 'package:autism_learning_assistant/models/activity_attempt.dart';
import 'package:autism_learning_assistant/models/activity_result.dart';
import 'package:autism_learning_assistant/services/performance_analyzer.dart';

ActivityResult result({
  required String category,
  required double accuracy,
  int difficulty = 1,
  DateTime? timestamp,
}) {
  final correct = accuracy.round();
  final total = 100;
  final correctCount = (correct / 100 * total).round();
  final attempts = <ActivityAttempt>[];
  for (var i = 0; i < total; i++) {
    attempts.add(
      ActivityAttempt(
        childId: 1,
        activityId: 1,
        questionIndex: i,
        isCorrect: i < correctCount,
        responseTime: const Duration(seconds: 2),
        timestamp: timestamp ?? DateTime(2026, 8, 1),
      ),
    );
  }
  return ActivityResult(
    childId: 1,
    activityId: 1,
    category: category,
    difficulty: difficulty,
    attempts: attempts,
    score: correctCount,
    totalQuestions: total,
    correctAnswers: correctCount,
    wrongAnswers: total - correctCount,
    totalAttempts: total,
    accuracy: accuracy,
    averageResponseTime: 2000,
    isCompleted: true,
    timestamp: timestamp ?? DateTime(2026, 8, 1),
  );
}

void main() {
  const analyzer = PerformanceAnalyzer();

  test('analyzes accuracy, response time and attempts', () {
    final analysis = analyzer.analyze([
      result(category: 'numbers', accuracy: 80),
    ]);

    expect(analysis.accuracy, 80);
    expect(analysis.totalAttempts, 100);
    expect(analysis.averageResponseTimeMs, 2000);
    expect(analysis.categoryPerformance['numbers']!.accuracy, 80);
  });

  test('detects consistently strong category', () {
    final analysis = analyzer.analyze([
      result(
        category: 'numbers',
        accuracy: 80,
        timestamp: DateTime(2026, 8, 1),
      ),
      result(
        category: 'numbers',
        accuracy: 90,
        timestamp: DateTime(2026, 8, 2),
      ),
    ]);
    expect(analysis.strengths, contains('numbers'));
  });

  test('detects weak category needing practice', () {
    final analysis = analyzer.analyze([
      result(
        category: 'numbers',
        accuracy: 40,
        timestamp: DateTime(2026, 8, 1),
      ),
      result(
        category: 'numbers',
        accuracy: 50,
        timestamp: DateTime(2026, 8, 2),
      ),
    ]);
    expect(analysis.areasNeedingPractice, contains('numbers'));
  });

  test('tracks recent performance and improvement over time', () {
    final analysis = analyzer.analyze([
      result(
        category: 'numbers',
        accuracy: 48,
        timestamp: DateTime(2026, 8, 1),
      ),
      result(
        category: 'numbers',
        accuracy: 67,
        timestamp: DateTime(2026, 8, 2),
      ),
      result(
        category: 'numbers',
        accuracy: 88,
        timestamp: DateTime(2026, 8, 3),
      ),
    ]);
    expect(analysis.improvementByCategory['numbers'], [48, 67, 88]);
    expect(analysis.categoryPerformance['numbers']!.improvement, 40);
    expect(analysis.recentPerformance.length, 3);
  });

  test('handles empty data', () {
    final analysis = analyzer.analyze([]);
    expect(analysis.hasData, false);
    expect(analysis.totalAttempts, 0);
    expect(analysis.strengths, isEmpty);
  });
}
