import '../../models/api/api_progress.dart';
import 'api_client.dart';

/// Backend-aligned progress service.
///
/// Mirrors FastAPI `/progress/child/{child_id}` route.
class ApiProgressService {
  final ApiClient _client;

  const ApiProgressService({required this._client});

  Future<List<ApiProgress>> getByChild(int childId) async {
    final list = await _client.getJsonList('/progress/child/$childId');
    return list
        .map((e) => ApiProgress.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
