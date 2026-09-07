/// Backend-aligned child model.
///
/// Mirrors the FastAPI `Child` SQLAlchemy model:
/// id, parent_id, name, age, avatar, learning_preferences, created_at.
class ApiChild {
  final int id;
  final int parentId;
  final String name;
  final int age;
  final String? avatar;
  final String? learningPreferences;
  final String? createdAt;

  const ApiChild({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    this.avatar,
    this.learningPreferences,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'parent_id': parentId,
    'name': name,
    'age': age,
    'avatar': avatar,
    'learning_preferences': learningPreferences,
    'created_at': createdAt,
  };

  factory ApiChild.fromJson(Map<String, dynamic> json) => ApiChild(
    id: json['id'] as int,
    parentId: json['parent_id'] as int,
    name: json['name'] as String,
    age: json['age'] as int,
    avatar: json['avatar'] as String?,
    learningPreferences: json['learning_preferences'] as String?,
    createdAt: json['created_at'] as String?,
  );
}
