import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autism_learning_assistant/services/api/api_services.dart';
import 'package:autism_learning_assistant/services/app_session.dart';

import '../helpers/fake_backend.dart';

/// Integration tests for the session lifecycle against an in-process fake
/// backend: sign-in, catalogue loading, child selection and restore.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.debugReset();
    AppSession.debugReset();
  });

  group('AppSession', () {
    test('sign-in loads the activity catalogue', () async {
      final backend = standardBackend();
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      final user = await AppSession.instance.signIn(
        'maria@example.com',
        'secret',
      );

      expect(user.role, 'parent');
      expect(AppSession.instance.isSignedIn, true);
      // Signed in but no child selected yet: syncing stays disabled.
      expect(AppSession.instance.isActive, false);
      expect(AppSession.instance.activityForCategory('colors')?.id, 11);
      expect(AppSession.instance.activityForCategory('Shapes')?.id, 12);
      expect(AppSession.instance.activityForCategory('numbers'), isNull);
    });

    test('a parent selects a child and the choice survives restore', () async {
      final backend = standardBackend();
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');
      final session = AppSession.instance;
      await session.signIn('maria@example.com', 'secret');

      final children = await session.loadChildren();
      expect(children.map((c) => c.name), ['Alex']);
      await session.setActiveChild(children.first);
      expect(session.isActive, true);

      // Simulate an app restart: everything is restored from storage.
      AppSession.debugReset();
      await session.restore();

      expect(session.isActive, true);
      expect(session.activeChild?.id, 7);
      expect(session.activityForCategory('colors')?.id, 11);
    });

    test('restore without a stored token stays in local mode', () async {
      final backend = standardBackend();
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      await AppSession.instance.restore();

      expect(AppSession.instance.isSignedIn, false);
      expect(AppSession.instance.isActive, false);
      expect(backend.requests, isEmpty);
    });

    test('sign-out returns the app to local mode', () async {
      final backend = standardBackend();
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');
      final session = AppSession.instance;
      await session.signIn('maria@example.com', 'secret');
      await session.setActiveChild((await session.loadChildren()).first);
      expect(session.isActive, true);

      await session.signOut();

      expect(session.isSignedIn, false);
      expect(session.isActive, false);
      expect(session.activityForCategory('colors'), isNull);
      expect(ApiClient.instance.isAuthenticated, false);
    });

    test('a teacher seeds the four frontend activities when the catalogue '
        'is empty', () async {
      final backend = standardBackend()
        ..onPost('/auth/login', (_) => loginResponse(teacherUserJson))
        ..onGet('/activities/', () => const <Map<String, dynamic>>[]);
      final seeded = <String>[];
      backend.onPost('/activities/', (body) {
        seeded.add(body['category'] as String);
        return {
          'id': 100 + seeded.length,
          'name': body['name'],
          'category': body['category'],
          'description': body['description'],
          'difficulty': body['difficulty'],
        };
      });
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      await AppSession.instance.signIn('sam@school.edu', 'secret');

      expect(seeded, ['colors', 'shapes', 'numbers', 'words']);
      expect(AppSession.instance.activityForCategory('words')?.id, 104);
      expect(AppSession.instance.user?.role, 'teacher');
    });

    test('a parent does not seed missing catalogue activities', () async {
      final backend = standardBackend()
        ..onGet('/activities/', () => const <Map<String, dynamic>>[]);
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');

      await AppSession.instance.signIn('maria@example.com', 'secret');

      expect(backend.requestsFor('POST', '/activities/'), isEmpty);
      expect(AppSession.instance.activityForCategory('colors'), isNull);
    });

    test('a teacher sees the children assigned to them', () async {
      final backend = standardBackend()
        ..onPost('/auth/login', (_) => loginResponse(teacherUserJson))
        ..onGet('/assignments/user/2', () {
          return [
            {'id': 1, 'child_id': 7, 'user_id': 2, 'role': 'teacher'},
          ];
        });
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');
      final session = AppSession.instance;
      await session.signIn('sam@school.edu', 'secret');

      final children = await session.loadChildren();

      expect(children, hasLength(1));
      expect(children.single.id, 7);
      expect(children.single.name, 'Child #7');
    });

    test('single-child accounts skip the selection step on restore', () async {
      final backend = standardBackend();
      ApiClient.debugOverrideHttpClient(backend);
      await ApiClient.instance.setBaseUrl('http://localhost:8000');
      final session = AppSession.instance;
      await session.signIn('maria@example.com', 'secret');

      AppSession.debugReset();
      await session.restore();

      // The parent has exactly one child, so it is auto-selected.
      expect(session.isActive, true);
      expect(session.activeChild?.name, 'Alex');
    });
  });
}
