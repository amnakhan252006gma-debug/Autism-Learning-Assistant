/// Backend-aligned user model.
///
/// Mirrors the FastAPI `User` SQLAlchemy model:
/// id, name, email, password, role.
class ApiUser {
  final int id;
  final String name;
  final String email;
  final String role;

  const ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
  };

  factory ApiUser.fromJson(Map<String, dynamic> json) => ApiUser(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
  );
}
