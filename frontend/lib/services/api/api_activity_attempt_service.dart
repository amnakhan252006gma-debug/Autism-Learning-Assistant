import '../../models/api/api_activity_attempt.dart';
import 'api_client.dart';

/// Backend-aligned activity attempts service.
///
/// Mirrors FastAPI `/activity-attempts` routes: create, list by child.
class ApiActivityAttemptService {
  final ApiClient _client;

  const ApiActivityAttemptService({required this._client});

  Future<ApiActivityAttempt> create(ApiActivityAttempt attempt) async {
    final json = await _client.postJson(
      // Trailing slash: the backend route is POST /activity-attempts/.
      '/activity-attempts/',
      body: attempt.toJson(),
    );
    return ApiActivityAttempt.fromJson(json);
  }

  Future<List<ApiActivityAttempt>> getByChild(int childId) async {
    final list = await _client.getJsonList('/activity-attempts/child/$childId');
    return list
        .map((e) => ApiActivityAttempt.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
