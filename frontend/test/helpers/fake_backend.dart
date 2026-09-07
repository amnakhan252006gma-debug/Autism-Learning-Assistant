import 'dart:convert';

import 'package:http/http.dart' as http;

/// One request recorded by [FakeBackend].
class RecordedRequest {
  const RecordedRequest({
    required this.method,
    required this.path,
    required this.headers,
    this.body,
  });

  final String method;
  final String path;
  final Map<String, String> headers;
  final Map<String, dynamic>? body;

  @override
  String toString() => '$method $path';
}

/// Minimal in-process stand-in for the FastAPI backend.
///
/// Routes requests through programmable JSON handlers and records every
/// request so tests can assert on what the app actually sent. Unmatched
/// routes answer 404 the same way the real API would.
class FakeBackend extends http.BaseClient {
  final requests = <RecordedRequest>[];

  final _getHandlers = <String, Object? Function()>{};
  final _postHandlers = <String, Object? Function(Map<String, dynamic>)>{};
  final _failures = <String, int>{};

  /// Serve [json] for `GET [path]`.
  void onGet(String path, Object? Function() handler) {
    _getHandlers[path] = handler;
  }

  /// Serve JSON for `POST [path]`, receiving the decoded request body.
  void onPost(
    String path,
    Object? Function(Map<String, dynamic> body) handler,
  ) {
    _postHandlers[path] = handler;
  }

  /// Make the next [count] `METHOD /path` requests fail with HTTP 500.
  void failNext(String method, String path, int count) {
    _failures['$method $path'] = count;
  }

  /// All recorded requests for `METHOD /path`.
  List<RecordedRequest> requestsFor(String method, String path) => [
    for (final request in requests)
      if (request.method == method && request.path == path) request,
  ];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request && request.body.isNotEmpty
        ? jsonDecode(request.body) as Map<String, dynamic>
        : null;
    requests.add(
      RecordedRequest(
        method: request.method,
        path: request.url.path,
        headers: {
          for (final entry in request.headers.entries)
            entry.key.toLowerCase(): entry.value,
        },
        body: body,
      ),
    );

    final failureKey = '${request.method} ${request.url.path}';
    final failuresLeft = _failures[failureKey] ?? 0;
    if (failuresLeft > 0) {
      _failures[failureKey] = failuresLeft - 1;
      return _respond(request, 500, {'detail': 'internal server error'});
    }

    if (request.method == 'GET') {
      final handler = _getHandlers[request.url.path];
      if (handler == null) {
        return _respond(request, 404, {'detail': 'Not Found'});
      }
      return _respond(request, 200, handler());
    }
    if (request.method == 'POST') {
      final handler = _postHandlers[request.url.path];
      if (handler == null) {
        return _respond(request, 404, {'detail': 'Not Found'});
      }
      return _respond(request, 201, handler(body ?? {}));
    }
    return _respond(request, 405, {'detail': 'Method Not Allowed'});
  }

  http.StreamedResponse _respond(
    http.BaseRequest request,
    int status,
    Object? json,
  ) {
    final bytes = utf8.encode(jsonEncode(json));
    return http.StreamedResponse(
      Stream.value(bytes),
      status,
      contentLength: bytes.length,
      headers: {'content-type': 'application/json; charset=utf-8'},
      request: request,
    );
  }
}

const Map<String, dynamic> parentUserJson = {
  'id': 1,
  'name': 'Maria',
  'email': 'maria@example.com',
  'role': 'parent',
};

const Map<String, dynamic> teacherUserJson = {
  'id': 2,
  'name': 'Sam',
  'email': 'sam@school.edu',
  'role': 'teacher',
};

const Map<String, dynamic> childJson = {
  'id': 7,
  'parent_id': 1,
  'name': 'Alex',
  'age': 5,
  'avatar': 'A',
  'learning_preferences': null,
  'created_at': '2026-09-01T10:00:00',
};

const List<Map<String, dynamic>> activitiesJson = [
  {
    'id': 11,
    'name': 'Colors',
    'category': 'colors',
    'description': 'Match and identify colors',
    'difficulty': 1,
  },
  {
    'id': 12,
    'name': 'Shapes',
    'category': 'shapes',
    'description': 'Discover shapes around you',
    'difficulty': 2,
  },
];

const Map<String, dynamic> analysisJson = {
  'child_id': 7,
  'performance': {
    'child_id': 7,
    'overall_accuracy': 72.5,
    'category_performance': {
      'colors': {'accuracy': 80.0, 'activities_completed': 4},
      'shapes': {'accuracy': 65.0, 'activities_completed': 2},
    },
    'strengths': ['colors'],
    'weak_areas': ['shapes'],
    'message': null,
  },
  'difficulty': {
    'colors': {
      'current_difficulty': 1,
      'next_difficulty': 2,
      'accuracy': 80.0,
      'reason': 'Accuracy 80% reached the 80% threshold',
    },
    'shapes': {
      'current_difficulty': 2,
      'next_difficulty': 1,
      'accuracy': 40.0,
      'reason': 'Accuracy 40% is below the 50% threshold',
    },
  },
  'recommendations': [
    {
      'category': 'shapes',
      'difficulty': 1,
      'priority': 'high',
      'reason': 'Focus on shapes practice',
    },
  ],
  // The real backend returns ai_insight as a nested object.
  'ai_insight': {
    'overall_status': 'Good Progress',
    'summary':
        'The child is making good progress with an overall accuracy of 72.5%.',
    'strengths': ['colors'],
    'areas_to_improve': ['shapes'],
    'parent_advice':
        'Focus additional practice on shapes. Start with manageable activities.',
    'category_insights': [
      {
        'category': 'colors',
        'accuracy': 80.0,
        'activities_completed': 4,
        'status': 'Strong',
        'recommended_difficulty': 2,
        'message': 'The child is performing strongly in colors.',
      },
      {
        'category': 'shapes',
        'accuracy': 65.0,
        'activities_completed': 2,
        'status': 'Developing',
        'recommended_difficulty': 1,
        'message': 'The child is developing skills in shapes.',
      },
    ],
  },
};

/// Backend wired with the happy-path handlers shared by most tests.
///
/// Paths mirror the FastAPI router definitions exactly (collection routes
/// carry a trailing slash) and responses mirror the live backend, including
/// the `"result": {}` quirk of POST /activity-results/ (the nested progress
/// recomputation expires the ORM object before serialisation).
FakeBackend standardBackend() {
  return FakeBackend()
    ..onPost('/auth/login', (body) {
      return {
        'message': 'Login successful',
        'access_token': 'jwt-token-123',
        'token_type': 'bearer',
        'user': parentUserJson,
      };
    })
    ..onPost('/auth/register', (body) {
      return {
        'message': 'Registration successful',
        'access_token': 'jwt-token-123',
        'token_type': 'bearer',
        'user': parentUserJson,
      };
    })
    ..onGet('/auth/me', () => parentUserJson)
    ..onGet('/activities/', () => activitiesJson)
    ..onGet('/children/', () => [childJson])
    ..onGet('/analysis/child/7', () => analysisJson)
    ..onGet('/activity-results/child/7', () => const <Map<String, dynamic>>[])
    ..onPost('/activity-attempts/', (body) {
      return {...body, 'id': 99, 'created_at': '2026-09-01T10:00:00'};
    })
    ..onPost('/activity-results/', (body) {
      return {
        'message': 'Activity result saved successfully',
        'result': <String, dynamic>{},
        'progress': {
          'id': 9,
          'child_id': 7,
          'category': 'colors',
          'accuracy': 80.0,
          'score': 240.0,
          'activities_completed': 4,
          'current_difficulty': 2,
          'updated_at': '2026-09-01T10:00:00',
        },
      };
    });
}

/// Happy-path login response for [userJson] (used to switch roles).
Map<String, dynamic> loginResponse(Map<String, dynamic> userJson) => {
  'message': 'Login successful',
  'access_token': 'jwt-token-123',
  'token_type': 'bearer',
  'user': userJson,
};
