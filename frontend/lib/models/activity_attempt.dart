/// Records a single answer attempt during a learning activity.
///
/// One [ActivityAttempt] is created per tap on an answer choice.
class ActivityAttempt {
  final int childId;
  final int activityId;
  final int questionIndex;
  final bool isCorrect;
  final Duration responseTime;
  final DateTime timestamp;
  final int attemptNumber;

  const ActivityAttempt({
    required this.childId,
    required this.activityId,
    required this.questionIndex,
    required this.isCorrect,
    required this.responseTime,
    required this.timestamp,
    this.attemptNumber = 1,
  });

  Map<String, dynamic> toJson() => {
    'child_id': childId,
    'activity_id': activityId,
    'question_index': questionIndex,
    'correct': isCorrect,
    'response_time': responseTime.inMilliseconds / 1000,
    'attempt_number': attemptNumber,
  };

  factory ActivityAttempt.fromJson(Map<String, dynamic> json) {
    final responseTimeValue = json['response_time'];

    return ActivityAttempt(
      childId: json['child_id'] as int,
      activityId: json['activity_id'] as int,
      questionIndex: (json['question_index'] ?? 0) as int,
      isCorrect: (json['correct'] ?? json['is_correct']) as bool,
      responseTime: Duration(
        milliseconds: responseTimeValue is num
            ? (responseTimeValue * 1000).round()
            : 0,
      ),
      attemptNumber: (json['attempt_number'] ?? 1) as int,
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
