import '../models/performance_analysis.dart';
import 'difficulty_engine.dart';

class ActivityRecommendation {
  final String category;
  final String title;
  final String difficulty;
  final String reason;
  final double priority;

  const ActivityRecommendation({
    required this.category,
    required this.title,
    required this.difficulty,
    required this.reason,
    required this.priority,
  });
}

/// Selects the next local activity without coupling recommendation logic to UI.
class RecommendationEngine {
  final DifficultyEngine difficultyEngine;

  const RecommendationEngine({this.difficultyEngine = const DifficultyEngine()});

  List<ActivityRecommendation> recommend({
    required PerformanceAnalysis analysis,
    int limit = 3,
  }) {
    const activities = [
      ('colors', 'Colors'),
      ('shapes', 'Shapes'),
      ('numbers', 'Numbers'),
      ('words', 'Words'),
    ];

    final candidates = activities.map((activity) {
      final category = activity.$1;
      final title = activity.$2;
      final performance = analysis.categoryPerformance[category];
      final isWeak = analysis.areasNeedingPractice.contains(category);
      final isStrength = analysis.strengths.contains(category);
      final improvement = performance?.improvement ?? 0;
      final recent = performance?.recentAccuracy ?? 0;

      double priority = 10;
      String reason = 'A good next activity to keep learning and practicing.';

      if (isWeak) {
        priority += 100;
        reason = 'Recommended because you need more practice with $title.';
      } else if (performance != null && improvement > 5) {
        priority += 60;
        reason = 'Recommended because your $title skills are improving.';
      } else if (performance != null && recent >= 60) {
        priority += 35;
        reason = 'Recommended to build on your recent progress in $title.';
      } else if (isStrength) {
        priority += 15;
        reason = 'Recommended to keep your strong $title skills growing.';
      }

      final difficulty = performance == null
          ? 'easy'
          : difficultyEngine
              .chooseDifficulty(
                category: category,
                currentDifficulty: performance.currentDifficulty,
                analysis: analysis,
              )
              .difficulty;
      return ActivityRecommendation(
        category: category,
        title: title,
        difficulty: difficulty,
        reason: reason,
        priority: priority,
      );
    }).toList();

    candidates.sort((a, b) => b.priority.compareTo(a.priority));
    return candidates.take(limit).toList(growable: false);
  }

}
