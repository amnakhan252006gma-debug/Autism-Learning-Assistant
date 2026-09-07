import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autism_learning_assistant/models/activity_attempt.dart';
import 'package:autism_learning_assistant/models/activity_result.dart';
import 'package:autism_learning_assistant/services/activity_result_repository.dart';

void main() {
  // ── ActivityAttempt ──────────────────────────────────────────────

  group('ActivityAttempt', () {
    test('records all required fields', () {
      final now = DateTime(2026, 8, 30, 10, 0);
      final a = ActivityAttempt(
        childId: 1,
        activityId: 1,
        questionIndex: 2,
        isCorrect: false,
        responseTime: const Duration(milliseconds: 2500),
        timestamp: now,
      );

      expect(a.childId, 1);
      expect(a.activityId, 1);
      expect(a.questionIndex, 2);
      expect(a.isCorrect, false);
      expect(a.responseTime, const Duration(milliseconds: 2500));
      expect(a.timestamp, now);
    });

    test('JSON round-trip preserves all fields', () {
      final now = DateTime(2026, 8, 30, 10, 30);
      final original = ActivityAttempt(
        childId: 1,
        activityId: 2,
        questionIndex: 3,
        isCorrect: true,
        responseTime: const Duration(milliseconds: 1800),
        timestamp: now,
      );

      final json = original.toJson();
      final restored = ActivityAttempt.fromJson(json);

      expect(restored.childId, original.childId);
      expect(restored.activityId, original.activityId);
      expect(restored.questionIndex, original.questionIndex);
      expect(restored.isCorrect, original.isCorrect);
      expect(
        restored.responseTime.inMilliseconds,
        original.responseTime.inMilliseconds,
      );
      expect(restored.timestamp, original.timestamp);
    });
  });

  // ── ActivityResult ───────────────────────────────────────────────

  group('ActivityResult', () {
    final baseTime = DateTime(2026, 8, 30, 10, 0);

    List<ActivityAttempt> buildAttempts({
      required int count,
      required List<bool> correctFlags,
    }) {
      return List.generate(count, (i) {
        return ActivityAttempt(
          childId: 1,
          activityId: 1,
          questionIndex: i,
          isCorrect: correctFlags[i],
          responseTime: Duration(milliseconds: (i + 1) * 1000),
          timestamp: baseTime.add(Duration(seconds: i * 5)),
        );
      });
    }

    test('fromAttempts computes stats correctly', () {
      // 3 questions, 5 total taps: correct, wrong, correct, wrong, correct
      final attempts = [
        ActivityAttempt(
          childId: 1,
          activityId: 1,
          questionIndex: 0,
          isCorrect: true,
          responseTime: const Duration(seconds: 2),
          timestamp: baseTime,
        ),
        ActivityAttempt(
          childId: 1,
          activityId: 1,
          questionIndex: 1,
          isCorrect: false,
          responseTime: const Duration(seconds: 3),
          timestamp: baseTime,
        ),
        ActivityAttempt(
          childId: 1,
          activityId: 1,
          questionIndex: 1,
          isCorrect: true,
          responseTime: const Duration(seconds: 4),
          timestamp: baseTime,
        ),
        ActivityAttempt(
          childId: 1,
          activityId: 1,
          questionIndex: 2,
          isCorrect: false,
          responseTime: const Duration(seconds: 2),
          timestamp: baseTime,
        ),
        ActivityAttempt(
          childId: 1,
          activityId: 1,
          questionIndex: 2,
          isCorrect: true,
          responseTime: const Duration(seconds: 3),
          timestamp: baseTime,
        ),
      ];

      final result = ActivityResult.fromAttempts(
        childId: 1,
        activityId: 1,
        category: 'colors',
        difficulty: 1,
        attempts: attempts,
        score: 1, // only first-attempt corrects (question 0)
        totalQuestions: 3,
      );

      expect(result.correctAnswers, 3);
      expect(result.wrongAnswers, 2);
      expect(result.totalAttempts, 5);
      expect(result.score, 1);
      expect(result.totalQuestions, 3);
      expect(result.isCompleted, true);
      // accuracy = 3/5 * 100 = 60.0
      expect(result.accuracy, closeTo(60.0, 0.01));
      // avg response time = (2000+3000+4000+2000+3000)/5 = 2800
      expect(result.averageResponseTime, closeTo(2800.0, 0.01));
    });

    test('fromAttempts handles zero attempts', () {
      final result = ActivityResult.fromAttempts(
        childId: 1,
        activityId: 1,
        category: 'colors',
        difficulty: 1,
        attempts: const [],
        score: 0,
        totalQuestions: 5,
      );

      expect(result.correctAnswers, 0);
      expect(result.wrongAnswers, 0);
      expect(result.totalAttempts, 0);
      expect(result.accuracy, 0.0);
      expect(result.averageResponseTime, 0.0);
    });

    test('JSON round-trip preserves all fields', () {
      final attempts = buildAttempts(count: 2, correctFlags: [true, false]);
      final original = ActivityResult.fromAttempts(
        childId: 1,
        activityId: 1,
        category: 'numbers',
        difficulty: 1,
        attempts: attempts,
        score: 1,
        totalQuestions: 2,
      );

      final json = original.toJson();
      final restored = ActivityResult.fromJson(json);

      expect(restored.childId, original.childId);
      expect(restored.activityId, original.activityId);
      expect(restored.category, original.category);
      expect(restored.difficulty, original.difficulty);
      expect(restored.attempts.length, original.attempts.length);
      expect(restored.score, original.score);
      expect(restored.totalQuestions, original.totalQuestions);
      expect(restored.correctAnswers, original.correctAnswers);
      expect(restored.wrongAnswers, original.wrongAnswers);
      expect(restored.totalAttempts, original.totalAttempts);
      expect(restored.accuracy, closeTo(original.accuracy, 0.01));
      expect(
        restored.averageResponseTime,
        closeTo(original.averageResponseTime, 0.01),
      );
      expect(restored.isCompleted, original.isCompleted);
    });
  });

  // ── ActivityResultRepository ─────────────────────────────────────

  group('ActivityResultRepository', () {
    late ActivityResultRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = ActivityResultRepository();
      await repo.initialise();
    });

    ActivityResult makeResult({
      required int activityId,
      required String category,
      required int score,
      required int totalQuestions,
      required List<ActivityAttempt> attempts,
      DateTime? timestamp,
    }) {
      final result = ActivityResult.fromAttempts(
        childId: 1,
        activityId: activityId,
        category: category,
        difficulty: 1,
        attempts: attempts,
        score: score,
        totalQuestions: totalQuestions,
      );
      if (timestamp == null) return result;
      return ActivityResult(
        childId: result.childId,
        activityId: result.activityId,
        category: result.category,
        difficulty: result.difficulty,
        attempts: result.attempts,
        score: result.score,
        totalQuestions: result.totalQuestions,
        correctAnswers: result.correctAnswers,
        wrongAnswers: result.wrongAnswers,
        totalAttempts: result.totalAttempts,
        accuracy: result.accuracy,
        averageResponseTime: result.averageResponseTime,
        isCompleted: result.isCompleted,
        timestamp: timestamp,
      );
    }

    ActivityAttempt makeAttempt({
      required int questionIndex,
      required bool isCorrect,
    }) {
      return ActivityAttempt(
        childId: 1,
        activityId: 1,
        questionIndex: questionIndex,
        isCorrect: isCorrect,
        responseTime: const Duration(seconds: 2),
        timestamp: DateTime(2026, 8, 30, 10, 0),
      );
    }

    test('saves and retrieves a result', () async {
      final result = makeResult(
        activityId: 1,
        category: 'colors',
        score: 3,
        totalQuestions: 5,
        attempts: List.generate(
          5,
          (i) => makeAttempt(questionIndex: i, isCorrect: i < 3),
        ),
      );

      await repo.saveResult(result);
      final all = await repo.getAllResults();

      expect(all.length, 1);
      expect(all.first.score, 3);
      expect(all.first.category, 'colors');
    });

    test('stores multiple results', () async {
      await repo.saveResult(
        makeResult(
          activityId: 1,
          category: 'colors',
          score: 4,
          totalQuestions: 5,
          attempts: List.generate(
            5,
            (i) => makeAttempt(questionIndex: i, isCorrect: i < 4),
          ),
        ),
      );
      await repo.saveResult(
        makeResult(
          activityId: 2,
          category: 'shapes',
          score: 3,
          totalQuestions: 5,
          attempts: List.generate(
            5,
            (i) => makeAttempt(questionIndex: i, isCorrect: i < 3),
          ),
        ),
      );

      final all = await repo.getAllResults();
      expect(all.length, 2);
    });

    test('filters by child and activity', () async {
      await repo.saveResult(
        makeResult(
          activityId: 1,
          category: 'colors',
          score: 5,
          totalQuestions: 5,
          attempts: List.generate(
            5,
            (i) => makeAttempt(questionIndex: i, isCorrect: true),
          ),
        ),
      );

      final forChild = await repo.getResultsForChild(1);
      expect(forChild.length, 1);

      final forActivity = await repo.getResultsForActivity(1);
      expect(forActivity.length, 1);

      final forOther = await repo.getResultsForChild(2);
      expect(forOther.length, 0);
    });

    test('clearAll removes everything', () async {
      await repo.saveResult(
        makeResult(
          activityId: 3,
          category: 'numbers',
          score: 2,
          totalQuestions: 5,
          attempts: List.generate(
            5,
            (i) => makeAttempt(questionIndex: i, isCorrect: i < 2),
          ),
        ),
      );

      await repo.clearAll();
      final all = await repo.getAllResults();
      expect(all, isEmpty);
    });

    test('getStatsForChild aggregates across results', () async {
      // Result 1: 3/5 correct on first attempt, 6 total taps
      await repo.saveResult(
        makeResult(
          activityId: 1,
          category: 'colors',
          score: 3,
          totalQuestions: 5,
          attempts: [
            makeAttempt(questionIndex: 0, isCorrect: true),
            makeAttempt(questionIndex: 1, isCorrect: false),
            makeAttempt(questionIndex: 1, isCorrect: true),
            makeAttempt(questionIndex: 2, isCorrect: false),
            makeAttempt(questionIndex: 2, isCorrect: true),
            makeAttempt(questionIndex: 3, isCorrect: true),
          ],
        ),
      );

      final stats = await repo.getStatsForChild(1);

      expect(stats['total_questions'], 5);
      expect(stats['correct_answers'], 4);
      expect(stats['total_attempts'], 6);
      expect(stats['activities_completed'], 1);
    });

    test('getStatsByCategory groups correctly', () async {
      await repo.saveResult(
        makeResult(
          activityId: 1,
          category: 'colors',
          score: 5,
          totalQuestions: 5,
          attempts: List.generate(
            5,
            (i) => makeAttempt(questionIndex: i, isCorrect: true),
          ),
        ),
      );
      await repo.saveResult(
        makeResult(
          activityId: 2,
          category: 'shapes',
          score: 2,
          totalQuestions: 5,
          attempts: List.generate(
            5,
            (i) => makeAttempt(questionIndex: i, isCorrect: i < 2),
          ),
        ),
      );

      final byCat = await repo.getStatsByCategory(1);

      expect(byCat.containsKey('colors'), true);
      expect(byCat.containsKey('shapes'), true);
      expect(byCat['colors']!['correct_answers'], 5);
      expect(byCat['shapes']!['correct_answers'], 2);
    });

    test('getSummary identifies strongest and weakest', () async {
      await repo.saveResult(
        makeResult(
          activityId: 1,
          category: 'colors',
          score: 5,
          totalQuestions: 5,
          attempts: List.generate(
            5,
            (i) => makeAttempt(questionIndex: i, isCorrect: true),
          ),
        ),
      );
      await repo.saveResult(
        makeResult(
          activityId: 2,
          category: 'shapes',
          score: 1,
          totalQuestions: 5,
          attempts: [
            makeAttempt(questionIndex: 0, isCorrect: true),
            makeAttempt(questionIndex: 1, isCorrect: false),
            makeAttempt(questionIndex: 1, isCorrect: false),
            makeAttempt(questionIndex: 1, isCorrect: false),
            makeAttempt(questionIndex: 1, isCorrect: false),
          ],
        ),
      );

      final summary = await repo.getSummary(1);

      expect(summary['strongest_category'], 'colors');
      expect(summary['weakest_category'], 'shapes');
    });

    test('getRecentResults returns newest first, capped', () async {
      final base = DateTime(2026, 8, 30, 10, 0);
      for (int i = 0; i < 5; i++) {
        await repo.saveResult(
          makeResult(
            activityId: 100,
            category: 'colors',
            score: i,
            totalQuestions: 5,
            attempts: List.generate(
              5,
              (j) => makeAttempt(questionIndex: j, isCorrect: j < i),
            ),
            timestamp: base.add(Duration(minutes: i)),
          ),
        );
      }

      final recent = await repo.getRecentResults(1, 3);
      expect(recent.length, 3);
      // Newest first: run_4 has score 4, run_3 has score 3, run_2 has score 2
      expect(recent[0].score, 4);
      expect(recent[1].score, 3);
      expect(recent[2].score, 2);
    });
  });
}
