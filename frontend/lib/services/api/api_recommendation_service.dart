import '../../models/api/api_recommendation_response.dart';
import 'api_client.dart';

/// Backend-aligned recommendations service.
///
/// Mirrors FastAPI `/recommendations/child/{child_id}` route.
class ApiRecommendationService {
  final ApiClient _client;

  const ApiRecommendationService({required this._client});

  Future<ApiRecommendationResponse> getByChild(int childId) async {
    final json = await _client.getJson('/recommendations/child/$childId');
    return ApiRecommendationResponse.fromJson(json);
  }
}
