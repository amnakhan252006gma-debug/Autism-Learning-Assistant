/// Backend-aligned child assignment model.
///
/// Mirrors the FastAPI ChildAssignment model.
class ApiChildAssignment {
  final int id;
  final int childId;
  final int userId;
  final String role;

  const ApiChildAssignment({
    required this.id,
    required this.childId,
    required this.userId,
    required this.role,
  });

  factory ApiChildAssignment.fromJson(Map<String, dynamic> json) {
    return ApiChildAssignment(
      id: json['id'] as int,
      childId: json['child_id'] as int,
      userId: json['user_id'] as int,
      role: json['role'] as String,
    );
  }
}
