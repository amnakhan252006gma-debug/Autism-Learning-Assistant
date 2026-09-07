import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autism_learning_assistant/models/activity_attempt.dart';
import 'package:autism_learning_assistant/models/activity_result.dart';
import 'package:autism_learning_assistant/models/api/api_child.dart';
import 'package:autism_learning_assistant/services/api/api_services.dart';
import 'package:autism_learning_assistant/services/app_session.dart';
import 'package:autism_learning_assistant/services/backend_sync_service.dart';

import '../helpers/fake_backend.dart';

/// Integration tests for the offline-first sync between locally stored
/// activity results and the backend, including the retry queue.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.debugReset();
    AppSession.debugReset();
  });

  /// A finished 'medium' colors session: question 0 correct on the first
  /// try, question 1 wrong once then correct on the retry.
  ActivityResult buildResult() {
    final start = DateTime(2026, 9, 1, 10, 0);
    return ActivityResult.fromAttempts(
      childId: 1,
      activityId: 1,
      category: 'colors',
      difficulty: 2,
      attempts: [
        ActivityAttempt(
          childId: 1,
          activityId: 1,
          questionIndex: 0,
          isCorrect: true,
          responseTime: const Duration(seconds: 2),
          timestamp: start,
        ),
        ActivityAttempt(
          childId: 1,
          activityId: 1,
          questionIndex: 1,
          isCorrect: false,
          responseTime: const Duration(seconds: 3),
          timestamp: start.add(const Duration(seconds: 5)),
        ),
        ActivityAttempt(
          childId: 1,
          activityId: 1,
          questionIndex: 1,
          isCorrect: true,
          responseTime: const Duration(seconds: 2),
          timestamp: start.add(const Duration(seconds: 10)),
        ),
      ],
      score: 1,
      totalQuestions: 2,
    );
  }

  Future<void> activateSession(FakeBackend backend) async {
    ApiClient.debugOverrideHttpClient(backend);
    await ApiClient.instance.setBaseUrl('http://localhost:8000');
    await AppSession.instance.signIn('maria@example.com', 'secret');
    await AppSession.instance.setActiveChild(
      const ApiChild(id: 7, parentId: 1, name: 'Alex', age: 5),
    );
  }

  group('BackendSyncService', () {
    test('is a no-op while no session is active', () async {
      final backend = standardBackend();
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      await BackendSyncService.instance.syncActivityResult(
        buildResult(),
        childId: 7,
        activityId: 11,
      );

      expect(backend.requests, isEmpty);
      expect(await BackendSyncService.instance.queuedCount(), 0);
    });

    test('pushes every attempt and then the aggregate result', () async {
      final backend = standardBackend();
      await activateSession(backend);

      await BackendSyncService.instance.syncActivityResult(
        buildResult(),
        childId: 7,
        activityId: 11,
      );

      // Question 1 was answered twice: its retry carries attempt_number 2.
      final attempts = backend.requestsFor('POST', '/activity-attempts/');
      expect(attempts, hasLength(3));
      expect(attempts.map((r) => r.body!['attempt_number']).toList(), [
        1,
        1,
        2,
      ]);
      expect(attempts.map((r) => r.body!['correct']).toList(), [
        true,
        false,
        true,
      ]);
      expect(attempts.map((r) => r.body!['response_time']).toList(), [
        2.0,
        3.0,
        2.0,
      ]);

      expect(backend.requestsFor('POST', '/activity-results/').single.body, {
        'child_id': 7,
        'activity_id': 11,
        'difficulty': 2, // 'medium' -> backend level 2
        'score': 1.0,
        'correct_answers': 2,
        'incorrect_answers': 1,
        'attempts': 3,
        'time_taken': 7.0, // 2s + 3s + 2s total response time
        'completion_status': 'completed',
      });
      expect(await BackendSyncService.instance.queuedCount(), 0);
    });

    test('queues the aggregate result while the backend is down and drains '
        'it after the next sync', () async {
      final backend = standardBackend()
        ..failNext('POST', '/activity-results/', 1);
      await activateSession(backend);

      await BackendSyncService.instance.syncActivityResult(
        buildResult(),
        childId: 7,
        activityId: 11,
      );
      // Attempts still went through live; only the aggregate result failed.
      expect(backend.requestsFor('POST', '/activity-attempts/'), hasLength(3));
      expect(await BackendSyncService.instance.queuedCount(), 1);

      await BackendSyncService.instance.syncActivityResult(
        buildResult(),
        childId: 7,
        activityId: 11,
      );
      expect(await BackendSyncService.instance.queuedCount(), 0);
      // First upload failed, then the retry and the second live result.
      expect(backend.requestsFor('POST', '/activity-results/'), hasLength(3));
    });

    test('drops a queued result once the retry budget is exhausted', () async {
      final backend = standardBackend()
        ..failNext('POST', '/activity-results/', 99);
      await activateSession(backend);

      await BackendSyncService.instance.syncActivityResult(
        buildResult(),
        childId: 7,
        activityId: 11,
      );
      expect(await BackendSyncService.instance.queuedCount(), 1);

      await BackendSyncService.instance.retryQueued();
      await BackendSyncService.instance.retryQueued();
      expect(await BackendSyncService.instance.queuedCount(), 1);

      // Third failed retry: the budget (maxAttempts = 3) is spent.
      await BackendSyncService.instance.retryQueued();
      expect(await BackendSyncService.instance.queuedCount(), 0);
    });

    test(
      'failed per-answer attempts do not block the aggregate result',
      () async {
        final backend = standardBackend()
          ..failNext('POST', '/activity-attempts/', 99);
        await activateSession(backend);

        await BackendSyncService.instance.syncActivityResult(
          buildResult(),
          childId: 7,
          activityId: 11,
        );

        // Attempts are optional telemetry; the aggregate still uploads.
        expect(await BackendSyncService.instance.queuedCount(), 0);
        expect(backend.requestsFor('POST', '/activity-results/'), hasLength(1));
      },
    );
  });
}
