/// Backend-aligned activity result model.
///
/// Mirrors the FastAPI `ActivityResult` SQLAlchemy model:
/// id, child_id, activity_id, difficulty, score, correct_answers,
/// incorrect_answers, attempts, time_taken, completion_status, created_at.
///
/// Note: the backend stores aggregate counts only, not the embedded attempt
/// list used by the local [ActivityResult] model.
class ApiActivityResult {
  final int? id;
  final int childId;
  final int activityId;
  final int difficulty;
  final double score;
  final int correctAnswers;
  final int incorrectAnswers;
  final int attempts;
  final double? timeTaken;
  final String completionStatus;
  final String? createdAt;

  const ApiActivityResult({
    this.id,
    required this.childId,
    required this.activityId,
    required this.difficulty,
    required this.score,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.attempts,
    this.timeTaken,
    required this.completionStatus,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'child_id': childId,
    'activity_id': activityId,
    'difficulty': difficulty,
    'score': score,
    'correct_answers': correctAnswers,
    'incorrect_answers': incorrectAnswers,
    'attempts': attempts,
    'time_taken': timeTaken,
    'completion_status': completionStatus,
  };

  factory ApiActivityResult.fromJson(Map<String, dynamic> json) =>
      ApiActivityResult(
        id: json['id'] as int?,
        childId: json['child_id'] as int,
        activityId: json['activity_id'] as int,
        difficulty: json['difficulty'] as int,
        score: (json['score'] as num).toDouble(),
        correctAnswers: json['correct_answers'] as int,
        incorrectAnswers: json['incorrect_answers'] as int,
        attempts: json['attempts'] as int,
        timeTaken: (json['time_taken'] as num?)?.toDouble(),
        completionStatus: json['completion_status'] as String,
        createdAt: json['created_at'] as String?,
      );
}
