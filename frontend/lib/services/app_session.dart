import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api/api_activity.dart';
import '../models/api/api_child.dart';
import '../models/api/api_user.dart';
import 'api/api_services.dart';
import 'api/api_client.dart';

/// Active backend session for the app.
///
/// Holds the signed-in [ApiUser], the selected [ApiChild] and the backend
/// activity catalogue. The app stays fully usable in local mode while no
/// session is active: every backend interaction goes through this class, so
/// screens only need to check [isActive] before making network calls.
class AppSession {
  AppSession._();

  static final AppSession _instance = AppSession._();

  /// Singleton instance.
  static AppSession get instance => _instance;

  static const String _activeChildKey = 'app_active_child_id';

  /// Frontend activity categories that can be mirrored on the backend.
  static const List<(String, String, String)> knownActivities = [
    ('colors', 'Colors', 'Match and identify colors'),
    ('shapes', 'Shapes', 'Discover shapes around you'),
    ('numbers', 'Numbers', 'Count and build confidence'),
    ('words', 'Words', 'Learn new everyday words'),
  ];

  final ApiClient _client = ApiClient.instance;

  // Backend-aligned services bound to the shared HTTP client.
  late final ApiAuthService auth = ApiAuthService(client: _client);
  late final ApiChildService children = ApiChildService(client: _client);
  late final ApiActivityService activities = ApiActivityService(
    client: _client,
  );
  late final ApiActivityAttemptService attempts = ApiActivityAttemptService(
    client: _client,
  );
  late final ApiActivityResultService results = ApiActivityResultService(
    client: _client,
  );
  late final ApiAnalysisService analysis = ApiAnalysisService(client: _client);
  late final ApiRecommendationService recommendations =
      ApiRecommendationService(client: _client);
  late final ApiProgressService progress = ApiProgressService(client: _client);
  late final ApiAssignmentService assignments = ApiAssignmentService(
    client: _client,
  );

  ApiUser? _user;
  ApiChild? _activeChild;
  final Map<String, ApiActivity> _activitiesByCategory = {};
  bool _restored = false;

  /// The signed-in user, or `null` in local mode.
  ApiUser? get user => _user;

  /// The child whose learning data is currently tracked.
  ApiChild? get activeChild => _activeChild;

  /// Whether a user is currently authenticated with the backend.
  bool get isSignedIn => _user != null;

  /// Whether backend syncing is enabled (user signed in + child selected).
  bool get isActive => _user != null && _activeChild != null;

  /// Restore a previously persisted session (token, user, child, activities).
  ///
  /// Safe to call repeatedly; never throws. Falls back to local mode whenever
  /// persistent storage or the backend is unavailable.
  Future<void> restore() async {
    if (_restored) return;
    _restored = true;

    try {
      await _client.initialise();
    } catch (_) {
      return; // Persistent storage unavailable (e.g. unit tests).
    }

    if (!_client.isAuthenticated) return;

    try {
      _user = await auth.getCurrentUser();
      await loadActivities();
      await _restoreActiveChild();
    } catch (_) {
      // Expired token or unreachable backend: continue in local mode.
      _user = null;
      _activeChild = null;
    }
  }

  /// Sign in with email + password and load the activity catalogue.
  Future<ApiUser> signIn(String email, String password) async {
    _user = await auth.login(email: email, password: password);
    await loadActivities();
    return _user!;
  }

  /// Register a new account, sign in with it and load the activity catalogue.
  Future<ApiUser> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final user = await auth.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    _user = await auth.login(email: email, password: password);
    await loadActivities();
    return user;
  }

  /// Load the activity catalogue used to map categories to backend ids.
  ///
  /// Teachers and therapists additionally seed the four frontend categories
  /// when the backend catalogue is still empty (parents are not allowed to
  /// create activities).
  Future<void> loadActivities() async {
    try {
      final catalogue = await activities.getAll();
      _activitiesByCategory
        ..clear()
        ..addEntries(
          catalogue.map((a) => MapEntry(a.category.toLowerCase(), a)),
        );
    } catch (_) {
      // The catalogue is optional; syncing is skipped for unknown categories.
      return;
    }

    if (_user == null || _user!.role == 'parent') return;

    for (final (category, name, description) in knownActivities) {
      if (_activitiesByCategory.containsKey(category)) continue;
      try {
        final created = await activities.create(
          name: name,
          category: category,
          description: description,
          difficulty: 1,
        );
        _activitiesByCategory[category] = created;
      } catch (_) {
        // Seeding is best effort (e.g. another device created it already).
      }
    }
  }

  /// The backend activity for a frontend category ('colors', 'shapes', ...),
  /// or `null` when the backend has no matching activity.
  ApiActivity? activityForCategory(String category) =>
      _activitiesByCategory[category.toLowerCase()];

  /// Children visible to the signed-in user.
  ///
  /// Parents see their own children; teachers and therapists see the children
  /// assigned to them. The assignment endpoint exposes child ids only, so
  /// placeholder names are derived from the id.
  Future<List<ApiChild>> loadChildren() async {
    final user = _user;
    if (user == null) return const [];

    if (user.role == 'parent') {
      return children.getAll();
    }

    final assigned = await assignments.getByUser(user.id);
    return [
      for (final assignment in assigned)
        ApiChild(
          id: assignment.childId,
          parentId: user.id,
          name: 'Child #${assignment.childId}',
          age: 0,
        ),
    ];
  }

  /// Select the child whose data drives the screens and the sync.
  Future<void> setActiveChild(ApiChild child) async {
    _activeChild = child;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_activeChildKey, child.id);
    } catch (_) {
      // Selection still works for this run even if it cannot be persisted.
    }
  }

  /// Clear the session and return to local mode.
  Future<void> signOut() async {
    _user = null;
    _activeChild = null;
    _activitiesByCategory.clear();
    try {
      await auth.logout();
    } catch (_) {
      // Token clearing is best effort.
    }
  }

  Future<void> _restoreActiveChild() async {
    final candidates = await loadChildren();

    int? storedId;
    try {
      final prefs = await SharedPreferences.getInstance();
      storedId = prefs.getInt(_activeChildKey);
    } catch (_) {
      // Fall through to single-child auto selection.
    }

    if (storedId != null) {
      final match = candidates.where((c) => c.id == storedId).firstOrNull;
      if (match != null) {
        _activeChild = match;
        return;
      }
    }

    // Single-child accounts skip the selection screen.
    if (candidates.length == 1) {
      _activeChild = candidates.first;
    }
  }

  /// Reset cached state. Only used by tests.
  @visibleForTesting
  static void debugReset() {
    final session = _instance;
    session._restored = false;
    session._user = null;
    session._activeChild = null;
    session._activitiesByCategory.clear();
  }
}
