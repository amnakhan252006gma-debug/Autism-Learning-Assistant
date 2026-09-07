import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_result.dart';

/// Local repository that persists and retrieves [ActivityResult]s
/// using [SharedPreferences].
///
/// Use [ActivityResultRepository.instance] to access the singleton
/// after [initialise] has been called once.
///
/// Provides CRUD operations and analytics queries that Day 3
/// adaptive AI and the parent dashboard will consume.
class ActivityResultRepository {
  static const String _key = 'activity_results_v1';

  ActivityResultRepository();

  static ActivityResultRepository? _instance;

  /// Access the shared repository (must call [initialise] first).
  static ActivityResultRepository get instance =>
      _instance ??= ActivityResultRepository();

  late final SharedPreferences _prefs;

  /// Initialise the repository with a [SharedPreferences] handle.
  /// Called once from [main] (or from test setUp).
  Future<void> initialise() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── CRUD ──────────────────────────────────────────────────────────

  /// Persist a completed [ActivityResult].
  Future<void> saveResult(ActivityResult result) async {
    final results = await getAllResults();
    results.add(result);
    await _prefs.setStringList(
      _key,
      results.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  /// Return every stored result, oldest first.
  Future<List<ActivityResult>> getAllResults() async {
    final raw = _prefs.getStringList(_key) ?? [];
    return raw
        .map(
          (e) => ActivityResult.fromJson(jsonDecode(e) as Map<String, dynamic>),
        )
        .toList();
  }

  /// Results for a specific child.
  Future<List<ActivityResult>> getResultsForChild(int childId) async {
    final all = await getAllResults();
    return all.where((r) => r.childId == childId).toList();
  }

  /// Results for a specific activity.
  Future<List<ActivityResult>> getResultsForActivity(int activityId) async {
    final all = await getAllResults();
    return all.where((r) => r.activityId == activityId).toList();
  }

  /// Wipe every stored result (handy for tests / logout).
  Future<void> clearAll() async {
    await _prefs.remove(_key);
  }

  // ── Analytics ─────────────────────────────────────────────────────

  /// Aggregate stats for a child across all their attempts.
  Future<Map<String, dynamic>> getStatsForChild(int childId) async {
    final results = await getResultsForChild(childId);
    if (results.isEmpty) return _emptyStats();

    final totalQuestions = results.fold<int>(
      0,
      (sum, r) => sum + r.totalQuestions,
    );
    final correctAnswers = results.fold<int>(
      0,
      (sum, r) => sum + r.correctAnswers,
    );
    final totalAttempts = results.fold<int>(
      0,
      (sum, r) => sum + r.totalAttempts,
    );
    final totalTime = results.fold<double>(
      0,
      (sum, r) => sum + r.averageResponseTime * r.totalAttempts,
    );

    return {
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'wrong_answers': totalAttempts - correctAnswers,
      'total_attempts': totalAttempts,
      'total_score': results.fold<int>(0, (sum, r) => sum + r.score),
      'accuracy': totalAttempts > 0
          ? correctAnswers / totalAttempts * 100
          : 0.0,
      'average_response_time_ms': totalAttempts > 0
          ? totalTime / totalAttempts
          : 0.0,
      'activities_completed': results.where((r) => r.isCompleted).length,
    };
  }

  /// Stats grouped by category (Colors, Shapes, Numbers, Words).
  Future<Map<String, Map<String, dynamic>>> getStatsByCategory(
    int childId,
  ) async {
    final results = await getResultsForChild(childId);
    final Map<String, List<ActivityResult>> byCategory = {};
    for (final r in results) {
      byCategory.putIfAbsent(r.category, () => []).add(r);
    }

    return byCategory.map((category, list) {
      final attempts = list.fold<int>(0, (s, r) => s + r.totalAttempts);
      final correct = list.fold<int>(0, (s, r) => s + r.correctAnswers);
      return MapEntry(category, {
        'total_attempts': attempts,
        'correct_answers': correct,
        'accuracy': attempts > 0 ? correct / attempts * 100 : 0.0,
        'activities_completed': list.where((r) => r.isCompleted).length,
      });
    });
  }

  /// Most recent results (newest first), capped at [limit].
  Future<List<ActivityResult>> getRecentResults(int childId, int limit) async {
    final results = await getResultsForChild(childId);
    final sorted = [...results]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  /// High-level summary suitable for the parent dashboard.
  Future<Map<String, dynamic>> getSummary(int childId) async {
    final stats = await getStatsForChild(childId);
    final categoryStats = await getStatsByCategory(childId);

    String? strongest;
    String? weakest;
    double bestAcc = -1;
    double worstAcc = double.infinity;
    categoryStats.forEach((cat, data) {
      final acc = data['accuracy'] as double;
      if (acc > bestAcc) {
        bestAcc = acc;
        strongest = cat;
      }
      if (acc < worstAcc) {
        worstAcc = acc;
        weakest = cat;
      }
    });

    return {
      ...stats,
      'strongest_category': strongest,
      'weakest_category': weakest,
      'category_stats': categoryStats,
    };
  }

  Map<String, dynamic> _emptyStats() => {
    'total_questions': 0,
    'correct_answers': 0,
    'wrong_answers': 0,
    'total_attempts': 0,
    'total_score': 0,
    'accuracy': 0.0,
    'average_response_time_ms': 0.0,
    'activities_completed': 0,
  };
}
