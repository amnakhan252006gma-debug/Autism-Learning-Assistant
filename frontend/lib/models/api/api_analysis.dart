import 'api_recommendation_shared.dart';

/// Backend-aligned analysis response.
///
/// Mirrors the payload returned by FastAPI `GET /analysis/child/{child_id}`:
/// child_id, performance, difficulty, recommendations, ai_insight.
class ApiAnalysis {
  final int childId;
  final ApiPerformance performance;
  final Map<String, ApiDifficultyDecision> difficulty;
  final List<ApiRecommendationItem> recommendations;
  final ApiAiInsight? aiInsight;

  const ApiAnalysis({
    required this.childId,
    required this.performance,
    required this.difficulty,
    required this.recommendations,
    this.aiInsight,
  });

  factory ApiAnalysis.fromJson(Map<String, dynamic> json) => ApiAnalysis(
    childId: json['child_id'] as int,
    performance: ApiPerformance.fromJson(
      json['performance'] as Map<String, dynamic>,
    ),
    difficulty: (json['difficulty'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        ApiDifficultyDecision.fromJson(value as Map<String, dynamic>),
      ),
    ),
    recommendations: (json['recommendations'] as List)
        .map((e) => ApiRecommendationItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    // The backend returns ai_insight as a nested object (overall_status,
    // summary, ...). Older deployments sent a plain string; those are
    // ignored rather than crashing the whole analysis parse.
    aiInsight: json['ai_insight'] is Map<String, dynamic>
        ? ApiAiInsight.fromJson(json['ai_insight'] as Map<String, dynamic>)
        : null,
  );
}

/// Performance section of the analysis response.
class ApiPerformance {
  final int? childId;
  final double overallAccuracy;
  final Map<String, ApiCategoryPerformance> categoryPerformance;
  final List<String> strengths;
  final List<String> weakAreas;
  final String? message;

  const ApiPerformance({
    this.childId,
    required this.overallAccuracy,
    required this.categoryPerformance,
    required this.strengths,
    required this.weakAreas,
    this.message,
  });

  factory ApiPerformance.fromJson(Map<String, dynamic> json) => ApiPerformance(
    childId: json['child_id'] as int?,
    overallAccuracy: (json['overall_accuracy'] as num).toDouble(),
    categoryPerformance: (json['category_performance'] as Map<String, dynamic>)
        .map(
          (key, value) => MapEntry(
            key,
            ApiCategoryPerformance.fromJson(value as Map<String, dynamic>),
          ),
        ),
    strengths: (json['strengths'] as List).cast<String>(),
    weakAreas: (json['weak_areas'] as List).cast<String>(),
    message: json['message'] as String?,
  );
}

/// Per-category performance inside the analysis response.
class ApiCategoryPerformance {
  final double accuracy;
  final int activitiesCompleted;

  const ApiCategoryPerformance({
    required this.accuracy,
    required this.activitiesCompleted,
  });

  factory ApiCategoryPerformance.fromJson(Map<String, dynamic> json) =>
      ApiCategoryPerformance(
        accuracy: (json['accuracy'] as num).toDouble(),
        activitiesCompleted: json['activities_completed'] as int,
      );
}
