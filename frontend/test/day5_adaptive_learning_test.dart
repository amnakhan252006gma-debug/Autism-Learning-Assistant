import 'package:flutter_test/flutter_test.dart';

import '../lib/models/activity_attempt.dart';
import '../lib/models/activity_result.dart';
import '../lib/services/difficulty_engine.dart';
import '../lib/services/performance_analyzer.dart';
import '../lib/services/recommendation_engine.dart';

ActivityResult result({
  required String category,
  required int difficulty,
  required int correct,
  int total = 5,
  int id = 1,
}) {
  final attempts = List.generate(
    total,
    (index) => ActivityAttempt(
      childId: 1,
      activityId: id,
      questionIndex: index,
      isCorrect: index < correct,
      responseTime: const Duration(milliseconds: 700),
      timestamp: DateTime(2026, 1, 1).add(Duration(minutes: index)),
    ),
  );

  return ActivityResult.fromAttempts(
    childId: 1,
    activityId: id,
    category: category,
    difficulty: difficulty,
    attempts: attempts,
    score: correct,
    totalQuestions: total,
  );
}

void main() {
  const analyzer = PerformanceAnalyzer();
  const difficultyEngine = DifficultyEngine();
  const recommendationEngine = RecommendationEngine();

  test('weak performance lowers difficulty when possible', () {
    final analysis = analyzer.analyze([
      result(category: 'numbers', difficulty: 2, correct: 2, id: 1),
    ]);

    final decision = difficultyEngine.chooseDifficulty(
      category: 'numbers',
      currentDifficulty: 'medium',
      analysis: analysis,
    );

    expect(decision.adjustment, DifficultyAdjustment.decrease);
    expect(decision.difficulty, 'easy');
  });

  test('strong performance raises difficulty after repeated success', () {
    final analysis = analyzer.analyze([
      result(category: 'numbers', difficulty: 2, correct: 5, id: 1),
      result(category: 'numbers', difficulty: 2, correct: 5, id: 2),
    ]);

    final decision = difficultyEngine.chooseDifficulty(
      category: 'numbers',
      currentDifficulty: 'medium',
      analysis: analysis,
    );

    expect(decision.adjustment, DifficultyAdjustment.increase);
    expect(decision.difficulty, 'hard');
  });

  test('weak Numbers performance receives a Numbers recommendation', () {
    final analysis = analyzer.analyze([
      result(category: 'numbers', difficulty: 2, correct: 1, id: 1),
    ]);

    final recommendations = recommendationEngine.recommend(analysis: analysis);

    expect(recommendations.first.category, 'numbers');
    expect(recommendations.first.title, 'Numbers');
    expect(recommendations.first.difficulty, 'easy');
  });

  test('improving performance is detected and can increase difficulty', () {
    final analysis = analyzer.analyze([
      result(category: 'numbers', difficulty: 2, correct: 2, id: 1),
      result(category: 'numbers', difficulty: 2, correct: 4, id: 2),
      result(category: 'numbers', difficulty: 2, correct: 5, id: 3),
    ]);

    expect(
      analysis.categoryPerformance['numbers']!.improvement,
      greaterThan(0),
    );
    final decision = difficultyEngine.chooseDifficulty(
      category: 'numbers',
      currentDifficulty: 'medium',
      analysis: analysis,
    );
    expect(decision.difficulty, 'hard');
  });
}
