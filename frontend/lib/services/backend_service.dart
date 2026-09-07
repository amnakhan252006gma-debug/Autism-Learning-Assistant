import '../models/activity_result.dart';
import '../models/api/api_activity.dart';
import '../models/api/api_activity_attempt.dart';
import '../models/api/api_activity_result.dart';
import '../models/api/api_child.dart';
import '../models/api/api_user.dart';
import 'api/api_client.dart';
import 'api/api_services.dart';
import 'app_session.dart';

/// Compatibility facade used by the existing child-facing screens.
///
/// The project had two backend layers at the same time: the screens expected
/// a BackendService, while the newer API implementation uses AppSession and
/// the Api* services. This class keeps the screen code stable and routes all
/// requests through the newer API layer.
class BackendService {
  BackendService._();

  static final BackendService _instance = BackendService._();

  static BackendService get instance => _instance;

  final AppSession _session = AppSession.instance;
  final ApiClient _client = ApiClient.instance;

  Future<void> initialize() async {
    await _session.restore();
  }

  Future<void> setBaseUrl(String baseUrl) async {
    await _client.setBaseUrl(baseUrl);
  }

  String get baseUrl => _client.baseUrl ?? ApiClient.defaultBaseUrl;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final user = await _session.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    return user.toJson();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final user = await _session.signIn(email, password);

    // If there is exactly one child, select it immediately. If there are
    // several, ChildLoginScreen will let the parent choose one.
    try {
      final children = await getChildren();
      if (children.length == 1) {
        await _session.setActiveChild(ApiChild.fromJson(children.first));
      }
    } catch (_) {
      // Login itself succeeded; child selection can happen later.
    }

    return user.toJson();
  }

  /// Select a backend child as the active child for subsequent requests.
  Future<void> selectChild(Map<String, dynamic> child) async {
    final id = child['id'];
    if (id is! int) {
      throw StateError('Invalid child id.');
    }
    final apiChild = ApiChild.fromJson(child);
    await _session.setActiveChild(apiChild);
  }

  Future<List<Map<String, dynamic>>> getChildren() async {
    final children = await _session.loadChildren();
    return children.map((child) => child.toJson()).toList();
  }

  Future<Map<String, dynamic>> createChild({
    required String name,
    required int age,
    String? avatar,
    String? learningPreferences,
  }) async {
    final child = await _session.children.create(
      name: name,
      age: age,
      avatar: avatar,
      learningPreferences: learningPreferences,
    );
    await _session.setActiveChild(child);
    return child.toJson();
  }

  Future<List<Map<String, dynamic>>> getActivities() async {
    final activities = await _session.activities.getAll();
    return activities.map((activity) => activity.toJson()).toList();
  }

  Future<List<Map<String, dynamic>>> getProgress(int childId) async {
    final progress = await _session.progress.getByChild(childId);
    return progress.map((item) => item.toJson()).toList();
  }

  Future<Map<String, dynamic>> getAnalysis(int childId) async {
    final analysis = await _session.analysis.getByChild(childId);
    return {
      'child_id': analysis.childId,
      'performance': {
        if (analysis.performance.childId != null)
          'child_id': analysis.performance.childId,
        'overall_accuracy': analysis.performance.overallAccuracy,
        'category_performance': {
          for (final entry in analysis.performance.categoryPerformance.entries)
            entry.key: {
              'accuracy': entry.value.accuracy,
              'activities_completed': entry.value.activitiesCompleted,
            },
        },
        'strengths': analysis.performance.strengths,
        'weak_areas': analysis.performance.weakAreas,
        if (analysis.performance.message != null)
          'message': analysis.performance.message,
      },
      'difficulty': {
        for (final entry in analysis.difficulty.entries)
          entry.key: {
            'current_difficulty': entry.value.currentDifficulty,
            'next_difficulty': entry.value.nextDifficulty,
            'accuracy': entry.value.accuracy,
            'reason': entry.value.reason,
          },
      },
      'recommendations': [
        for (final item in analysis.recommendations)
          {
            'category': item.category,
            'difficulty': item.difficulty,
            'priority': item.priority,
            'reason': item.reason,
          },
      ],
      if (analysis.aiInsight != null)
        'ai_insight': _aiInsightToJson(analysis.aiInsight!),
    };
  }

  Future<Map<String, dynamic>> getRecommendations(int childId) async {
    final response = await _session.recommendations.getByChild(childId);
    return {
      'child_id': response.childId,
      'difficulty': {
        for (final entry in response.difficulty.entries)
          entry.key: {
            'current_difficulty': entry.value.currentDifficulty,
            'next_difficulty': entry.value.nextDifficulty,
            'accuracy': entry.value.accuracy,
            'reason': entry.value.reason,
          },
      },
      'recommendations': [
        for (final item in response.recommendations)
          {
            'category': item.category,
            'difficulty': item.difficulty,
            'priority': item.priority,
            'reason': item.reason,
          },
      ],
    };
  }

  Future<void> sendAttempt({
    required int childId,
    required int activityId,
    required int difficulty,
    required bool correct,
    double? responseTime,
    required int attemptNumber,
  }) async {
    await _ensureActiveChild(childId);

    await _session.attempts.create(
      ApiActivityAttempt(
        childId: childId,
        activityId: activityId,
        difficulty: difficulty,
        correct: correct,
        responseTime: responseTime,
        attemptNumber: attemptNumber,
      ),
    );
  }

  Future<void> sendResult({
    required int childId,
    required int activityId,
    required int difficulty,
    required double score,
    required int correctAnswers,
    required int incorrectAnswers,
    required int attempts,
    double? timeTaken,
  }) async {
    await _ensureActiveChild(childId);

    await _session.results.create(
      ApiActivityResult(
        childId: childId,
        activityId: activityId,
        difficulty: difficulty,
        score: score,
        correctAnswers: correctAnswers,
        incorrectAnswers: incorrectAnswers,
        attempts: attempts,
        timeTaken: timeTaken,
        completionStatus: 'completed',
      ),
    );
  }

  Future<void> logout() async {
    await _session.signOut();
  }

  Future<void> _ensureActiveChild(int childId) async {
    if (_session.activeChild?.id == childId) return;

    try {
      final child = await _session.children.getById(childId);
      await _session.setActiveChild(child);
      return;
    } catch (_) {
      // For assigned teacher/therapist children, getById may be forbidden
      // depending on backend policy. Try the currently visible child list.
    }

    final children = await _session.loadChildren();
    final match = children.where((child) => child.id == childId);
    if (match.isNotEmpty) {
      await _session.setActiveChild(match.first);
      return;
    }

    throw StateError('Child $childId is not available to the current user.');
  }

  static Map<String, dynamic> _aiInsightToJson(dynamic insight) {
    return {
      'overall_status': insight.overallStatus,
      'summary': insight.summary,
      'strengths': insight.strengths,
      'areas_to_improve': insight.areasToImprove,
      'parent_advice': insight.parentAdvice,
      'category_insights': [
        for (final item in insight.categoryInsights)
          {
            'category': item.category,
            'accuracy': item.accuracy,
            'activities_completed': item.activitiesCompleted,
            'status': item.status,
            'recommended_difficulty': item.recommendedDifficulty,
            'message': item.message,
          },
      ],
    };
  }
}
