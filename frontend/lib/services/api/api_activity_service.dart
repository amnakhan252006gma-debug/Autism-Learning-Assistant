import '../../models/api/api_activity.dart';
import 'api_client.dart';

/// Backend-aligned activities service.
///
/// Mirrors FastAPI `/activities` routes: create, list, get by id.
class ApiActivityService {
  final ApiClient _client;

  const ApiActivityService({required this._client});

  Future<ApiActivity> create({
    required String name,
    required String category,
    String? description,
    int difficulty = 1,
  }) async {
    final json = await _client.postJson(
      // Trailing slash: the backend route is POST /activities/ and FastAPI
      // would otherwise answer the slash-less path with a redirect.
      '/activities/',
      body: {
        'name': name,
        'category': category,
        'description': description,
        'difficulty': difficulty,
      },
    );
    return ApiActivity.fromJson(json);
  }

  Future<List<ApiActivity>> getAll() async {
    final list = await _client.getJsonList('/activities/');
    return list
        .map((e) => ApiActivity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiActivity> getById(int activityId) async {
    final json = await _client.getJson('/activities/$activityId');
    return ApiActivity.fromJson(json);
  }
}
