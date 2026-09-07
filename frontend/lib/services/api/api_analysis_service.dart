import '../../models/api/api_analysis.dart';
import 'api_client.dart';

/// Backend-aligned analysis service.
///
/// Mirrors FastAPI `/analysis/child/{child_id}` route.
class ApiAnalysisService {
  final ApiClient _client;

  const ApiAnalysisService({required this._client});

  Future<ApiAnalysis> getByChild(int childId) async {
    final json = await _client.getJson('/analysis/child/$childId');
    return ApiAnalysis.fromJson(json);
  }
}
