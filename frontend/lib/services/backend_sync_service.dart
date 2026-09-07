import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_result.dart';
import '../models/api/api_activity_attempt.dart';
import '../models/api/api_activity_result.dart';
import 'api/api_mappers.dart';
import 'api/api_services.dart';
import 'app_session.dart';

/// Offline-first bridge between locally stored activity results and the
/// backend.
///
/// Results are always persisted locally first; this service then pushes the
/// aggregate result (plus each individual answer attempt) to the backend.
/// Aggregate results that fail are queued in [SharedPreferences] and retried
/// on the next app launch or after the next successful sync. Per-answer
/// attempts are supplementary telemetry and are only sent live.
class BackendSyncService {
  BackendSyncService._();

  static final BackendSyncService _instance = BackendSyncService._();

  /// Singleton instance.
  static BackendSyncService get instance => _instance;

  static const String _queueKey = 'backend_sync_queue_v1';

  /// How many times a queued result is retried before it is dropped.
  static const int maxAttempts = 3;

  /// Push a completed activity session to the backend. Never throws.
  Future<void> syncActivityResult(
    ActivityResult result, {
    required int childId,
    required int activityId,
  }) async {
    final session = AppSession.instance;
    if (!session.isActive) return;

    await _pushAttempts(result, childId: childId, activityId: activityId);

    final payload = ApiActivityResult(
      childId: childId,
      activityId: activityId,
      difficulty: result.difficulty,
      score: result.score.toDouble(),
      correctAnswers: result.correctAnswers,
      incorrectAnswers: result.wrongAnswers,
      attempts: result.totalAttempts,
      timeTaken: _totalResponseTimeSeconds(result),
      completionStatus: 'completed',
    );

    try {
      await session.results.create(payload);
      await retryQueued();
    } catch (_) {
      await _enqueue(payload);
    }
  }

  /// Retry previously queued results. Never throws.
  Future<void> retryQueued() async {
    final session = AppSession.instance;
    if (!session.isActive) return;

    final queue = await _loadQueue();
    if (queue.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final entry in queue) {
      final attempts = (entry['attempts'] as int? ?? 0) + 1;
      try {
        await session.results.create(
          ApiActivityResult.fromJson(entry['result'] as Map<String, dynamic>),
        );
      } catch (_) {
        if (attempts < maxAttempts) {
          remaining.add({...entry, 'attempts': attempts});
        }
      }
    }

    // Always persist: surviving entries change too (their attempt counter
    // must advance even when the queue length stays the same).
    await _saveQueue(remaining);
  }

  /// Number of results waiting to be uploaded (used by tests and debugging).
  Future<int> queuedCount() async => (await _loadQueue()).length;

  Future<void> _pushAttempts(
    ActivityResult result, {
    required int childId,
    required int activityId,
  }) async {
    final session = AppSession.instance;
    final difficulty = result.difficulty;
    final perQuestionAttemptNumber = <int, int>{};

    for (final attempt in result.attempts) {
      final number = (perQuestionAttemptNumber[attempt.questionIndex] ?? 0) + 1;
      perQuestionAttemptNumber[attempt.questionIndex] = number;
      try {
        await session.attempts.create(
          ApiActivityAttempt(
            childId: childId,
            activityId: activityId,
            difficulty: difficulty,
            correct: attempt.isCorrect,
            responseTime: attempt.responseTime.inMilliseconds / 1000,
            attemptNumber: number,
          ),
        );
      } catch (_) {
        // Per-answer attempts are optional telemetry; the aggregate result
        // below carries everything the backend analysis needs.
      }
    }
  }

  double _totalResponseTimeSeconds(ActivityResult result) {
    final milliseconds = result.attempts.fold<int>(
      0,
      (sum, attempt) => sum + attempt.responseTime.inMilliseconds,
    );
    return milliseconds / 1000;
  }

  Future<void> _enqueue(ApiActivityResult result) async {
    try {
      final queue = await _loadQueue();
      queue.add({'result': result.toJson(), 'attempts': 0});
      await _saveQueue(queue);
    } catch (_) {
      // Queue persistence is best effort.
    }
  }

  Future<List<Map<String, dynamic>>> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_queueKey) ?? const [];
      return [
        for (final entry in raw)
          if (jsonDecode(entry) is Map<String, dynamic>)
            jsonDecode(entry) as Map<String, dynamic>,
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_queueKey, [
        for (final entry in queue) jsonEncode(entry),
      ]);
    } catch (_) {
      // Best effort.
    }
  }
}
