import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autism_learning_assistant/models/api/api_activity_result.dart';
import 'package:autism_learning_assistant/services/api/api_services.dart';

import '../helpers/fake_backend.dart';

/// Integration tests for the API layer against an in-process fake backend
/// that mirrors the FastAPI response shapes.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.debugReset();
  });

  group('ApiClient', () {
    test('falls back to the default base URL when none is stored', () async {
      ApiClient.debugOverrideHttpClient(standardBackend());

      await ApiClient.instance.initialise();

      expect(ApiClient.instance.baseUrl, ApiClient.defaultBaseUrl);
      expect(ApiClient.instance.baseUrl, contains(':8000'));
    });

    test('setBaseUrl strips a trailing slash and persists the URL', () async {
      // Use a non-loopback URL: on Android the emulator cannot reach
      // localhost, so initialise() would replace it with 10.0.2.2.
      await ApiClient.instance.setBaseUrl('http://192.168.1.100:8000/');
      expect(ApiClient.instance.baseUrl, 'http://192.168.1.100:8000');

      // A later initialise() keeps the stored value instead of the default.
      await ApiClient.instance.initialise();
      expect(ApiClient.instance.baseUrl, 'http://192.168.1.100:8000');
    });

    test(
      'on Android, initialise() replaces a stored loopback URL with 10.0.2.2',
      () async {
        // The test environment simulates Android by default, so storing
        // a localhost URL and re-initialising must correct it.
        await ApiClient.instance.setBaseUrl('http://localhost:8000');
        await ApiClient.instance.initialise();
        expect(ApiClient.instance.baseUrl, 'http://10.0.2.2:8000');

        // Same fix for 127.0.0.1.
        await ApiClient.instance.setBaseUrl('http://127.0.0.1:8000');
        await ApiClient.instance.initialise();
        expect(ApiClient.instance.baseUrl, 'http://10.0.2.2:8000');
      },
    );

    test('getJsonList parses JSON array responses', () async {
      final backend = standardBackend();
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      final list = await ApiClient.instance.getJsonList('/children/');

      expect(list, hasLength(1));
      expect(list.first, isA<Map<String, dynamic>>());
      expect(list.first['name'], 'Alex');
    });

    test('attaches the bearer token once one is stored', () async {
      final backend = standardBackend();
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');
      await ApiClient.instance.setToken('jwt-token-123');

      await ApiClient.instance.getJson('/auth/me');

      expect(
        backend.requests.single.headers['authorization'],
        'Bearer jwt-token-123',
      );
    });

    test(
      'throws ApiException with status and body for non-2xx responses',
      () async {
        final backend = standardBackend();
        ApiClient.debugOverrideHttpClient(backend);
        await ApiClient.instance.setBaseUrl('http://localhost:8000');

        await expectLater(
          ApiClient.instance.getJson('/missing'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.body, 'body', contains('Not Found')),
          ),
        );
      },
    );

    test('fails fast when no base URL is configured', () async {
      await expectLater(
        ApiClient.instance.getJson('/children/'),
        throwsStateError,
      );
    });
  });

  group('ApiAuthService', () {
    test('login stores the JWT and parses the user', () async {
      final backend = standardBackend();
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      final user = await ApiAuthService(
        client: ApiClient.instance,
      ).login(email: 'maria@example.com', password: 'secret');

      expect(user.id, 1);
      expect(user.role, 'parent');
      expect(ApiClient.instance.isAuthenticated, true);
      expect(ApiClient.instance.token, 'jwt-token-123');

      final login = backend.requestsFor('POST', '/auth/login').single;
      expect(login.body, {'email': 'maria@example.com', 'password': 'secret'});
    });

    test('register parses the user from the nested payload', () async {
      final backend = standardBackend();
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      final user = await ApiAuthService(client: ApiClient.instance).register(
        name: 'Maria',
        email: 'maria@example.com',
        password: 'secret',
        role: 'parent',
      );

      expect(user.email, 'maria@example.com');
      final registration = backend.requestsFor('POST', '/auth/register').single;
      expect(registration.body?['role'], 'parent');
    });

    test('logout clears the stored token', () async {
      final backend = standardBackend();
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      final service = ApiAuthService(client: ApiClient.instance);
      await service.login(email: 'maria@example.com', password: 'secret');
      expect(ApiClient.instance.isAuthenticated, true);

      await service.logout();
      expect(ApiClient.instance.isAuthenticated, false);
    });
  });

  group('ApiChildService', () {
    test('getAll parses an array of children', () async {
      final backend = standardBackend();
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      final children = await ApiChildService(
        client: ApiClient.instance,
      ).getAll();

      expect(children, hasLength(1));
      expect(children.single.id, 7);
      expect(children.single.name, 'Alex');
    });

    test('create posts snake_case fields and parses the response', () async {
      final backend = standardBackend()..onPost('/children/', (_) => childJson);
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      final child = await ApiChildService(
        client: ApiClient.instance,
      ).create(name: 'Alex', age: 5, avatar: 'A');

      expect(child.id, 7);
      expect(backend.requestsFor('POST', '/children/').single.body, {
        'name': 'Alex',
        'age': 5,
        'avatar': 'A',
        'learning_preferences': null,
      });
    });
  });

  group('ApiAnalysisService', () {
    test('getByChild parses the full analysis payload', () async {
      final backend = standardBackend();
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      final analysis = await ApiAnalysisService(
        client: ApiClient.instance,
      ).getByChild(7);

      expect(analysis.childId, 7);
      expect(analysis.performance.overallAccuracy, 72.5);
      expect(analysis.performance.categoryPerformance['colors']!.accuracy, 80);
      expect(
        analysis.performance.categoryPerformance['shapes']!.activitiesCompleted,
        2,
      );
      expect(analysis.difficulty['colors']!.nextDifficulty, 2);
      expect(analysis.difficulty['shapes']!.nextDifficulty, 1);
      expect(analysis.recommendations.single.category, 'shapes');
      expect(analysis.recommendations.single.priority, 'high');

      // ai_insight is a nested object on the backend.
      final insight = analysis.aiInsight;
      expect(insight, isNotNull);
      expect(insight!.overallStatus, 'Good Progress');
      expect(insight.summary, contains('72.5%'));
      expect(insight.areasToImprove, ['shapes']);
      expect(insight.categoryInsights, hasLength(2));
      expect(insight.categoryInsights.first.category, 'colors');
      expect(insight.categoryInsights.first.recommendedDifficulty, 2);
    });

    test('getByChild tolerates a plain-string ai_insight from older '
        'deployments', () async {
      final backend = standardBackend()
        ..onGet(
          '/analysis/child/7',
          () => {
            ...analysisJson,
            'ai_insight': 'Alex is doing great with colors.',
          },
        );
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      final analysis = await ApiAnalysisService(
        client: ApiClient.instance,
      ).getByChild(7);

      expect(analysis.childId, 7);
      expect(analysis.aiInsight, isNull);
    });
  });

  group('ApiActivityResultService', () {
    test(
      'create tolerates the empty result object the live backend returns',
      () async {
        final backend = standardBackend();
        ApiClient.debugOverrideHttpClient(backend);
        await ApiClient.instance.setBaseUrl('http://localhost:8000');

        final response =
            await ApiActivityResultService(client: ApiClient.instance).create(
              const ApiActivityResult(
                childId: 7,
                activityId: 11,
                difficulty: 2,
                score: 1,
                correctAnswers: 2,
                incorrectAnswers: 1,
                attempts: 3,
                timeTaken: 7,
                completionStatus: 'completed',
              ),
            );

        // The expired ORM object serialises as {} — parsing must not throw.
        expect(response.message, 'Activity result saved successfully');
        expect(response.result, isNull);
        expect(response.progress?.currentDifficulty, 2);
        expect(response.progress?.activitiesCompleted, 4);
        expect(
          backend.requestsFor('POST', '/activity-results/').single.body,
          containsPair('completion_status', 'completed'),
        );
      },
    );

    test('getByChild parses the stored results', () async {
      final backend = standardBackend()
        ..onGet('/activity-results/child/7', () {
          return [
            {
              'id': 50,
              'child_id': 7,
              'activity_id': 11,
              'difficulty': 2,
              'score': 1.0,
              'correct_answers': 2,
              'incorrect_answers': 1,
              'attempts': 3,
              'time_taken': 7.0,
              'completion_status': 'completed',
              'created_at': '2026-09-01T10:00:00',
            },
          ];
        });
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      final results = await ApiActivityResultService(
        client: ApiClient.instance,
      ).getByChild(7);

      expect(results, hasLength(1));
      expect(results.single.id, 50);
      expect(results.single.completionStatus, 'completed');
    });
  });

  group('difficulty mappers', () {
    test('maps frontend labels to backend levels', () {
      expect(difficultyToInt('easy'), 1);
      expect(difficultyToInt('medium'), 2);
      expect(difficultyToInt('hard'), 3);
      expect(difficultyToInt('EASY'), 1);
      expect(difficultyToInt('unknown'), 1);
    });

    test('maps backend levels to frontend labels', () {
      expect(difficultyToString(1), 'easy');
      expect(difficultyToString(2), 'medium');
      expect(difficultyToString(3), 'hard');
      expect(difficultyToString(0), 'easy');
      expect(difficultyToString(9), 'easy');
    });
  });
}
