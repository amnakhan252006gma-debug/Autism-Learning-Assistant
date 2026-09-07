import '../models/activity_result.dart';
import '../models/performance_analysis.dart';
import 'api/api_mappers.dart';

/// Analyzes locally stored activity results.
///
/// All thresholds live here so this service can later be replaced by an AI
/// backend without requiring UI changes.
class PerformanceAnalyzer {
  static const double strongThreshold = 80.0;
  static const double moderateThreshold = 60.0;
  static const int recentWindow = 3;

  const PerformanceAnalyzer();

  PerformanceAnalysis analyze(List<ActivityResult> results) {
    if (results.isEmpty) {
      return const PerformanceAnalysis(
        accuracy: 0,
        averageResponseTimeMs: 0,
        totalAttempts: 0,
        totalResults: 0,
        strengths: [],
        areasNeedingPractice: [],
        categoryPerformance: {},
        difficultyPerformance: {},
        recentPerformance: [],
        improvementByCategory: {},
      );
    }

    final allAttempts = results
        .expand((r) => r.attempts)
        .toList(growable: false);
    final totalAttempts = allAttempts.length;
    final totalCorrect = allAttempts.where((a) => a.isCorrect).length;
    final totalTime = allAttempts.fold<double>(
      0,
      (sum, a) => sum + a.responseTime.inMilliseconds,
    );

    final sorted = [...results]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final categoryGroups = <String, List<ActivityResult>>{};
    final difficultyGroups = <String, List<ActivityResult>>{};
    for (final result in sorted) {
      categoryGroups.putIfAbsent(result.category, () => []).add(result);
      difficultyGroups
          .putIfAbsent(difficultyToString(result.difficulty), () => [])
          .add(result);
    }

    final categoryPerformance = <String, CategoryPerformance>{};
    final strengths = <String>[];
    final weaknesses = <String>[];
    final improvementByCategory = <String, List<double>>{};

    for (final entry in categoryGroups.entries) {
      final list = entry.value;
      final attempts = list.expand((r) => r.attempts).length;
      final correct = list
          .expand((r) => r.attempts)
          .where((a) => a.isCorrect)
          .length;
      final accuracy = attempts > 0 ? correct / attempts * 100 : 0.0;
      final time = attempts > 0
          ? list
                    .expand((r) => r.attempts)
                    .fold<double>(
                      0,
                      (sum, a) => sum + a.responseTime.inMilliseconds,
                    ) /
                attempts
          : 0.0;
      final recent = list.length <= recentWindow
          ? list
          : list.sublist(list.length - recentWindow);
      final recentAttempts = recent.expand((r) => r.attempts).length;
      final recentCorrect = recent
          .expand((r) => r.attempts)
          .where((a) => a.isCorrect)
          .length;
      final recentAccuracy = recentAttempts > 0
          ? recentCorrect / recentAttempts * 100
          : 0.0;
      final firstAccuracy = _accuracyOf(list.first);
      final lastAccuracy = _accuracyOf(list.last);
      final improvement = lastAccuracy - firstAccuracy;

      final points = list.map(_accuracyOf).toList(growable: false);
      improvementByCategory[entry.key] = points;

      categoryPerformance[entry.key] = CategoryPerformance(
        category: entry.key,
        accuracy: accuracy,
        averageResponseTimeMs: time,
        attempts: attempts,
        activitiesCompleted: list.where((r) => r.isCompleted).length,
        recentAccuracy: recentAccuracy,
        improvement: improvement,
        currentDifficulty: difficultyToString(list.last.difficulty),
      );

      final consistentlyStrong =
          recent.length >= 2 &&
          recent.every((r) => _accuracyOf(r) >= strongThreshold) &&
          recentAccuracy >= strongThreshold;
      final needsPractice =
          recentAccuracy < moderateThreshold ||
          list.every((r) => _accuracyOf(r) < moderateThreshold);

      if (consistentlyStrong) strengths.add(entry.key);
      if (needsPractice) weaknesses.add(entry.key);
    }

    final difficultyPerformance = <String, DifficultyPerformance>{};
    for (final entry in difficultyGroups.entries) {
      final attempts = entry.value.expand((r) => r.attempts).length;
      final correct = entry.value
          .expand((r) => r.attempts)
          .where((a) => a.isCorrect)
          .length;
      difficultyPerformance[entry.key] = DifficultyPerformance(
        difficulty: entry.key,
        accuracy: attempts > 0 ? correct / attempts * 100 : 0.0,
        attempts: attempts,
        activitiesCompleted: entry.value.where((r) => r.isCompleted).length,
      );
    }

    final recentResults = [...sorted].reversed.take(recentWindow).toList();
    final recentPerformance = recentResults
        .map(
          (r) => ActivityPerformancePoint(
            timestamp: r.timestamp,
            category: r.category,
            accuracy: _accuracyOf(r),
          ),
        )
        .toList(growable: false);

    return PerformanceAnalysis(
      accuracy: totalAttempts > 0 ? totalCorrect / totalAttempts * 100 : 0.0,
      averageResponseTimeMs: totalAttempts > 0
          ? totalTime / totalAttempts
          : 0.0,
      totalAttempts: totalAttempts,
      totalResults: results.length,
      strengths: List.unmodifiable(strengths),
      areasNeedingPractice: List.unmodifiable(weaknesses),
      categoryPerformance: Map.unmodifiable(categoryPerformance),
      difficultyPerformance: Map.unmodifiable(difficultyPerformance),
      recentPerformance: List.unmodifiable(recentPerformance),
      improvementByCategory: Map.unmodifiable(improvementByCategory),
    );
  }

  double _accuracyOf(ActivityResult result) => result.accuracy;
}
