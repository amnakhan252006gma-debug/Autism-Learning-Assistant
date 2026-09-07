/// Immutable analytics produced by [PerformanceAnalyzer].
///
/// This model intentionally contains plain Dart data so the analytics layer
/// can later be replaced by an AI/backend implementation without changing
/// the UI.
class PerformanceAnalysis {
  final double accuracy;
  final double averageResponseTimeMs;
  final int totalAttempts;
  final int totalResults;
  final List<String> strengths;
  final List<String> areasNeedingPractice;
  final Map<String, CategoryPerformance> categoryPerformance;
  final Map<String, DifficultyPerformance> difficultyPerformance;
  final List<ActivityPerformancePoint> recentPerformance;
  final Map<String, List<double>> improvementByCategory;

  const PerformanceAnalysis({
    required this.accuracy,
    required this.averageResponseTimeMs,
    required this.totalAttempts,
    required this.totalResults,
    required this.strengths,
    required this.areasNeedingPractice,
    required this.categoryPerformance,
    required this.difficultyPerformance,
    required this.recentPerformance,
    required this.improvementByCategory,
  });

  bool get hasData => totalResults > 0;
}

class CategoryPerformance {
  final String category;
  final double accuracy;
  final double averageResponseTimeMs;
  final int attempts;
  final int activitiesCompleted;
  final double recentAccuracy;
  final double improvement;
  final String currentDifficulty;

  const CategoryPerformance({
    required this.category,
    required this.accuracy,
    required this.averageResponseTimeMs,
    required this.attempts,
    required this.activitiesCompleted,
    required this.recentAccuracy,
    required this.improvement,
    required this.currentDifficulty,
  });
}

class DifficultyPerformance {
  final String difficulty;
  final double accuracy;
  final int attempts;
  final int activitiesCompleted;

  const DifficultyPerformance({
    required this.difficulty,
    required this.accuracy,
    required this.attempts,
    required this.activitiesCompleted,
  });
}

class ActivityPerformancePoint {
  final DateTime timestamp;
  final String category;
  final double accuracy;

  const ActivityPerformancePoint({
    required this.timestamp,
    required this.category,
    required this.accuracy,
  });
}
