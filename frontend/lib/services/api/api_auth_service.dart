import '../../models/api/api_user.dart';
import 'api_client.dart';

/// Backend-aligned authentication service.
///
/// Mirrors FastAPI `/auth` routes: register, login, get current user.
class ApiAuthService {
  final ApiClient _client;

  const ApiAuthService({required this._client});

  /// Register a new user with role `parent`, `teacher`, or `therapist`.
  Future<ApiUser> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final json = await _client.postJson(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      },
    );
    final userJson = json['user'] as Map<String, dynamic>;
    return ApiUser.fromJson(userJson);
  }

  /// Log in and store the returned JWT in [ApiClient].
  Future<ApiUser> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.postJson(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    final token = json['access_token'] as String;
    await _client.setToken(token);

    final userJson = json['user'] as Map<String, dynamic>;
    return ApiUser.fromJson(userJson);
  }

  /// Fetch the currently authenticated user.
  Future<ApiUser> getCurrentUser() async {
    final json = await _client.getJson('/auth/me');
    return ApiUser.fromJson(json);
  }

  /// Clear the stored token.
  Future<void> logout() async {
    await _client.clearToken();
  }
}
