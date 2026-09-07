import '../../models/api/api_child_assignment.dart';
import '../../models/api/api_user.dart';
import 'api_client.dart';

/// Backend-aligned child assignment service.
///
/// Handles assigning teachers and therapists to children.
class ApiAssignmentService {
  final ApiClient _client;

  const ApiAssignmentService({required this._client});

  Future<ApiChildAssignment> create({
    required int childId,
    required int userId,
    required String role,
  }) async {
    final json = await _client.postJson(
      '/assignments/',
      body: {'child_id': childId, 'user_id': userId, 'role': role},
    );

    return ApiChildAssignment.fromJson(json);
  }

  Future<List<ApiChildAssignment>> getByChild(int childId) async {
    final list = await _client.getJsonList('/assignments/child/$childId');

    return list
        .map((e) => ApiChildAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ApiChildAssignment>> getByUser(int userId) async {
    final list = await _client.getJsonList('/assignments/user/$userId');

    return list
        .map((e) => ApiChildAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Gets all available teachers and therapists.
  Future<List<ApiUser>> getStaff() async {
    final list = await _client.getJsonList('/users/staff');

    return list
        .map((e) => ApiUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> delete(int assignmentId) async {
    final response = await _client.delete('/assignments/$assignmentId');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(statusCode: response.statusCode, body: response.body);
    }
  }
}
