/// Backend-aligned activity attempt model.
///
/// Mirrors the FastAPI `ActivityAttempt` SQLAlchemy model:
/// id, child_id, activity_id, difficulty, correct, response_time,
/// attempt_number, created_at.
///
/// Note: the backend does not store a per-question index.
class ApiActivityAttempt {
  final int? id;
  final int childId;
  final int activityId;
  final int difficulty;
  final bool correct;
  final double? responseTime;
  final int attemptNumber;
  final String? createdAt;

  const ApiActivityAttempt({
    this.id,
    required this.childId,
    required this.activityId,
    required this.difficulty,
    required this.correct,
    this.responseTime,
    this.attemptNumber = 1,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'child_id': childId,
    'activity_id': activityId,
    'difficulty': difficulty,
    'correct': correct,
    'response_time': responseTime,
    'attempt_number': attemptNumber,
  };

  factory ApiActivityAttempt.fromJson(Map<String, dynamic> json) =>
      ApiActivityAttempt(
        id: json['id'] as int?,
        childId: json['child_id'] as int,
        activityId: json['activity_id'] as int,
        difficulty: json['difficulty'] as int,
        correct: json['correct'] as bool,
        responseTime: (json['response_time'] as num?)?.toDouble(),
        attemptNumber: json['attempt_number'] as int? ?? 1,
        createdAt: json['created_at'] as String?,
      );
}
