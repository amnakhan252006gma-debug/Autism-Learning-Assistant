import 'activity_attempt.dart';

/// Complete result of a single learning-activity session.
///
/// Created when an activity finishes.
class ActivityResult {
  final int childId;
  final int activityId;
  final String category;
  final int difficulty;
  final List<ActivityAttempt> attempts;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int totalAttempts;
  final double accuracy;
  final double averageResponseTime;
  final bool isCompleted;
  final DateTime timestamp;

  const ActivityResult({
    required this.childId,
    required this.activityId,
    required this.category,
    required this.difficulty,
    required this.attempts,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.totalAttempts,
    required this.accuracy,
    required this.averageResponseTime,
    required this.isCompleted,
    required this.timestamp,
  });

  factory ActivityResult.fromAttempts({
    required int childId,
    required int activityId,
    required String category,
    required int difficulty,
    required List<ActivityAttempt> attempts,
    required int score,
    required int totalQuestions,
  }) {
    final correctAnswers = attempts.where((a) => a.isCorrect).length;

    final wrongAnswers = attempts.where((a) => !a.isCorrect).length;

    final totalAttempts = attempts.length;

    final accuracy = totalAttempts > 0
        ? correctAnswers / totalAttempts * 100
        : 0.0;

    final avgTime = totalAttempts > 0
        ? attempts
                  .map((a) => a.responseTime.inMilliseconds)
                  .reduce((a, b) => a + b) /
              totalAttempts /
              1000
        : 0.0;

    return ActivityResult(
      childId: childId,
      activityId: activityId,
      category: category,
      difficulty: difficulty,
      attempts: attempts,
      score: score,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      totalAttempts: totalAttempts,
      accuracy: accuracy,
      averageResponseTime: avgTime,
      isCompleted: true,
      timestamp: DateTime.now(),
    );
  }

  /// JSON used by the frontend/local repository.
  Map<String, dynamic> toJson() => {
    'child_id': childId,
    'activity_id': activityId,
    'category': category,
    'difficulty': difficulty,
    'attempts': attempts.map((a) => a.toJson()).toList(),
    'score': score,
    'total_questions': totalQuestions,
    'correct_answers': correctAnswers,
    'wrong_answers': wrongAnswers,
    'total_attempts': totalAttempts,
    'accuracy': accuracy,
    'average_response_time': averageResponseTime,
    'is_completed': isCompleted,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ActivityResult.fromJson(Map<String, dynamic> json) {
    final rawAttempts = json['attempts'] as List<dynamic>? ?? [];

    return ActivityResult(
      childId: json['child_id'] as int,
      activityId: json['activity_id'] as int,
      category: json['category'] as String,
      difficulty: json['difficulty'] as int,
      attempts: rawAttempts
          .map((a) => ActivityAttempt.fromJson(a as Map<String, dynamic>))
          .toList(),
      score: (json['score'] ?? 0) as int,
      totalQuestions: (json['total_questions'] ?? 0) as int,
      correctAnswers: (json['correct_answers'] ?? 0) as int,
      wrongAnswers: (json['wrong_answers'] ?? 0) as int,
      totalAttempts: (json['total_attempts'] ?? 0) as int,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      averageResponseTime:
          (json['average_response_time'] as num?)?.toDouble() ?? 0.0,
      isCompleted: (json['is_completed'] ?? true) as bool,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}
