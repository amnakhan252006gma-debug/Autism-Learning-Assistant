import '../../models/api/api_child.dart';
import 'api_client.dart';

/// Backend-aligned children service.
///
/// Mirrors FastAPI `/children` routes: create, list, get, update, delete.
class ApiChildService {
  final ApiClient _client;

  const ApiChildService({required this._client});

  Future<ApiChild> create({
    required String name,
    required int age,
    String? avatar,
    String? learningPreferences,
  }) async {
    final json = await _client.postJson(
      // Trailing slash: the backend route is POST /children/ and FastAPI
      // would otherwise answer the slash-less path with a redirect.
      '/children/',
      body: {
        'name': name,
        'age': age,
        'avatar': avatar,
        'learning_preferences': learningPreferences,
      },
    );
    return ApiChild.fromJson(json);
  }

  Future<List<ApiChild>> getAll() async {
    final list = await _client.getJsonList('/children/');
    return list
        .map((e) => ApiChild.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiChild> getById(int childId) async {
    final json = await _client.getJson('/children/$childId');
    return ApiChild.fromJson(json);
  }

  Future<ApiChild> update(
    int childId, {
    String? name,
    int? age,
    String? avatar,
    String? learningPreferences,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'age': age,
      'avatar': avatar,
      'learning_preferences': learningPreferences,
    }..removeWhere((key, value) => value == null);
    final json = await _client.putJson('/children/$childId', body: body);
    return ApiChild.fromJson(json);
  }

  Future<void> delete(int childId) async {
    final response = await _client.delete('/children/$childId');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(statusCode: response.statusCode, body: response.body);
    }
  }
}
