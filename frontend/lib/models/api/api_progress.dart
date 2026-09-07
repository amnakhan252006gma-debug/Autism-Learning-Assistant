/// Backend-aligned progress model.
///
/// Mirrors the FastAPI `Progress` SQLAlchemy model:
/// id, child_id, category, accuracy, score, activities_completed,
/// current_difficulty, updated_at.
class ApiProgress {
  final int? id;
  final int childId;
  final String category;
  final double accuracy;
  final double score;
  final int activitiesCompleted;
  final int currentDifficulty;
  final String? updatedAt;

  const ApiProgress({
    this.id,
    required this.childId,
    required this.category,
    required this.accuracy,
    required this.score,
    required this.activitiesCompleted,
    required this.currentDifficulty,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'child_id': childId,
    'category': category,
    'accuracy': accuracy,
    'score': score,
    'activities_completed': activitiesCompleted,
    'current_difficulty': currentDifficulty,
    'updated_at': updatedAt,
  };

  factory ApiProgress.fromJson(Map<String, dynamic> json) => ApiProgress(
    id: json['id'] as int?,
    childId: json['child_id'] as int,
    category: json['category'] as String,
    accuracy: (json['accuracy'] as num).toDouble(),
    score: (json['score'] as num).toDouble(),
    activitiesCompleted: json['activities_completed'] as int,
    currentDifficulty: json['current_difficulty'] as int,
    updatedAt: json['updated_at'] as String?,
  );
}
