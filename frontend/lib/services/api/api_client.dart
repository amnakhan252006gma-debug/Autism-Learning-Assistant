import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Low-level HTTP client for the FastAPI backend.
///
/// Features:
/// - Attaches `Authorization: Bearer <token>` when a JWT is stored.
/// - Stores/loads the token using [SharedPreferences].
/// - Provides typed helpers for GET, POST, PUT, DELETE.
class ApiClient {
  ApiClient._();

  static const String _tokenKey = 'api_access_token';
  static const String _baseUrlKey = 'api_base_url';

  /// How long any single request may take before failing.
  static const Duration requestTimeout = Duration(seconds: 8);

  /// Default backend URL for the running platform.
  ///
  /// Android emulators reach the host machine via `10.0.2.2`; every other
  /// platform (iOS simulator, desktop, web) uses loopback.
  static String get defaultBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Whether [url] points at the host loopback — the address the Android
  /// emulator *cannot* reach.
  static bool _isLoopbackUrl(String url) {
    return url.contains('127.0.0.1') || url.contains('localhost');
  }

  static final ApiClient _instance = ApiClient._();

  /// Singleton instance.
  static ApiClient get instance => _instance;

  http.Client _httpClient = http.Client();

  String? _baseUrl;
  String? _token;

  /// Initialise the base URL and stored token from shared preferences.
  /// Call once at startup.
  ///
  /// On Android the emulator cannot reach the host's `127.0.0.1` or
  /// `localhost`; if the stored URL is one of those we silently correct
  /// it to the emulator-friendly `10.0.2.2` alias.
  Future<void> initialise() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey);
    _token = prefs.getString(_tokenKey);

    final bool isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    if (_baseUrl == null || _baseUrl!.isEmpty) {
      _baseUrl = defaultBaseUrl;
    } else if (isAndroid && _isLoopbackUrl(_baseUrl!)) {
      // A loopback URL persisted earlier (e.g. from desktop development)
      // cannot work inside the Android emulator — fix it now.
      _baseUrl = defaultBaseUrl;
      await prefs.setString(_baseUrlKey, _baseUrl!);
    }
  }

  /// Set the backend base URL, e.g. `http://10.0.2.2:8000`.
  Future<void> setBaseUrl(String baseUrl) async {
    _baseUrl = baseUrl.replaceAll(RegExp(r'/$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl!);
  }

  /// Current base URL, or `null` if not configured.
  String? get baseUrl => _baseUrl;

  /// Store a JWT access token.
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Clear the stored JWT (e.g. on logout).
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Whether a token is currently available.
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// The stored JWT, if any (used to forward the session between screens).
  String? get token => _token;

  /// Replace the underlying HTTP client. Only used by tests.
  @visibleForTesting
  static void debugOverrideHttpClient(http.Client client) {
    instance._httpClient = client;
  }

  /// Reset cached state (base URL, token, HTTP client). Only used by tests.
  @visibleForTesting
  static void debugReset() {
    instance._baseUrl = null;
    instance._token = null;
    instance._httpClient = http.Client();
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  String _buildUrl(String path) {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      throw StateError(
        'ApiClient base URL is not set. Call setBaseUrl(...) first.',
      );
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$_baseUrl$cleanPath';
  }

  Future<http.Response> get(String path) async {
    return _safeRequest(
      () => _httpClient.get(Uri.parse(_buildUrl(path)), headers: _headers),
    );
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    return _safeRequest(
      () => _httpClient.post(
        Uri.parse(_buildUrl(path)),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<http.Response> put(String path, {Map<String, dynamic>? body}) async {
    return _safeRequest(
      () => _httpClient.put(
        Uri.parse(_buildUrl(path)),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<http.Response> delete(String path) async {
    return _safeRequest(
      () => _httpClient.delete(Uri.parse(_buildUrl(path)), headers: _headers),
    );
  }

  /// Wraps every HTTP request so that low-level connection failures
  /// ([SocketException], [TimeoutException]) are surfaced as
  /// [ApiConnectionException] with a readable message.
  Future<http.Response> _safeRequest(
    Future<http.Response> Function() send,
  ) async {
    try {
      return await send().timeout(requestTimeout);
    } on SocketException catch (e) {
      throw ApiConnectionException(
        message:
            'Could not reach the server at $_baseUrl. '
            '${e.message.isEmpty ? 'Connection refused.' : e.message}',
      );
    } on TimeoutException {
      throw ApiConnectionException(
        message:
            'The server at $_baseUrl did not respond within '
            '${requestTimeout.inSeconds} seconds.',
      );
    }
  }

  /// Helper that parses a JSON object response.
  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await get(path);
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Helper that parses a JSON array response.
  Future<List<dynamic>> getJsonList(String path) async {
    final response = await get(path);
    _ensureSuccess(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  /// Helper that posts a JSON body and parses a JSON object response.
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await post(path, body: body);
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Helper that puts a JSON body and parses a JSON object response.
  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await put(path, body: body);
    _ensureSuccess(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(statusCode: response.statusCode, body: response.body);
    }
  }
}

/// Exception thrown when the backend returns a non-2xx status code.
class ApiException implements Exception {
  final int statusCode;
  final String body;

  const ApiException({required this.statusCode, required this.body});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, body: $body)';
}

/// Exception thrown when the device cannot reach the backend at all
/// (connection refused, DNS failure, timeout, etc.).
class ApiConnectionException implements Exception {
  final String message;

  const ApiConnectionException({required this.message});

  @override
  String toString() => 'ApiConnectionException: $message';
}
