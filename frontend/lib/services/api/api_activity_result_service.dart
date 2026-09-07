import '../../models/api/api_activity_result.dart';
import '../../models/api/api_progress.dart';
import 'api_client.dart';

/// Backend-aligned activity results service.
///
/// Mirrors FastAPI `/activity-results` routes: create, list by child.
class ApiActivityResultService {
  final ApiClient _client;

  const ApiActivityResultService({required this._client});

  Future<ApiActivityResultWithProgress> create(ApiActivityResult result) async {
    final json = await _client.postJson(
      '/activity-results/',
      body: result.toJson(),
    );
    return ApiActivityResultWithProgress.fromJson(json);
  }

  Future<List<ApiActivityResult>> getByChild(int childId) async {
    final list = await _client.getJsonList('/activity-results/child/$childId');
    return list
        .map((e) => ApiActivityResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Combined result returned by the backend when a new result is saved.
///
/// The backend recomputes the child's progress inside the create route,
/// which expires the freshly created result ORM object — so `result` comes
/// back as an empty object and is therefore nullable in practice.
class ApiActivityResultWithProgress {
  final String message;
  final ApiActivityResult? result;
  final ApiProgress? progress;

  const ApiActivityResultWithProgress({
    required this.message,
    required this.result,
    required this.progress,
  });

  factory ApiActivityResultWithProgress.fromJson(Map<String, dynamic> json) =>
      ApiActivityResultWithProgress(
        message: json['message'] as String? ?? '',
        result: _parseResult(json['result']),
        progress: json['progress'] is Map<String, dynamic>
            ? ApiProgress.fromJson(json['progress'] as Map<String, dynamic>)
            : null,
      );

  static ApiActivityResult? _parseResult(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    // The backend may serialise the expired ORM object as `{}`.
    if (raw['child_id'] == null || raw['activity_id'] == null) return null;
    return ApiActivityResult.fromJson(raw);
  }
}
