/// Backend-aligned activity metadata model.
///
/// Mirrors the FastAPI `Activity` SQLAlchemy model:
/// id, name, category, description, difficulty (1-3).
///
/// Note: the backend stores only activity metadata, not question banks.
/// The frontend keeps local question data in [MockActivityData].
class ApiActivity {
  final int id;
  final String name;
  final String category;
  final String? description;
  final int difficulty;

  const ApiActivity({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'difficulty': difficulty,
  };

  factory ApiActivity.fromJson(Map<String, dynamic> json) => ApiActivity(
    id: json['id'] as int,
    name: json['name'] as String,
    category: json['category'] as String,
    description: json['description'] as String?,
    difficulty: json['difficulty'] as int,
  );
}
