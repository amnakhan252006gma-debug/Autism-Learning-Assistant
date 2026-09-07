/// Shared recommendation primitives used by analysis and recommendation
/// responses from the backend.
library;

/// Difficulty recommendation returned by the backend analysis/recommendation
/// engines.
class ApiDifficultyDecision {
  final int currentDifficulty;
  final int nextDifficulty;
  final double accuracy;
  final String reason;

  const ApiDifficultyDecision({
    required this.currentDifficulty,
    required this.nextDifficulty,
    required this.accuracy,
    required this.reason,
  });

  factory ApiDifficultyDecision.fromJson(Map<String, dynamic> json) =>
      ApiDifficultyDecision(
        currentDifficulty: json['current_difficulty'] as int,
        nextDifficulty: json['next_difficulty'] as int,
        accuracy: (json['accuracy'] as num).toDouble(),
        reason: json['reason'] as String,
      );
}

/// A single recommendation item returned by the backend.
class ApiRecommendationItem {
  final String category;
  final int difficulty;
  final String priority;
  final String reason;

  const ApiRecommendationItem({
    required this.category,
    required this.difficulty,
    required this.priority,
    required this.reason,
  });

  factory ApiRecommendationItem.fromJson(Map<String, dynamic> json) =>
      ApiRecommendationItem(
        category: json['category'] as String,
        difficulty: json['difficulty'] as int,
        priority: json['priority'] as String,
        reason: json['reason'] as String,
      );
}

/// Parent-friendly AI insight returned by the backend analysis endpoint.
///
/// Mirrors the payload of `generate_ai_insight` in the FastAPI backend:
/// overall_status, summary, strengths, areas_to_improve, parent_advice,
/// category_insights.
class ApiAiInsight {
  final String overallStatus;
  final String summary;
  final List<String> strengths;
  final List<String> areasToImprove;
  final String parentAdvice;
  final List<ApiCategoryInsight> categoryInsights;

  const ApiAiInsight({
    required this.overallStatus,
    required this.summary,
    required this.strengths,
    required this.areasToImprove,
    required this.parentAdvice,
    required this.categoryInsights,
  });

  factory ApiAiInsight.fromJson(Map<String, dynamic> json) => ApiAiInsight(
    overallStatus: json['overall_status'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    strengths: (json['strengths'] as List?)?.cast<String>() ?? const [],
    areasToImprove:
        (json['areas_to_improve'] as List?)?.cast<String>() ?? const [],
    parentAdvice: json['parent_advice'] as String? ?? '',
    categoryInsights:
        (json['category_insights'] as List?)
            ?.map((e) => ApiCategoryInsight.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}

/// Per-category insight inside the AI insight payload.
class ApiCategoryInsight {
  final String category;
  final double accuracy;
  final int activitiesCompleted;
  final String status;
  final int recommendedDifficulty;
  final String message;

  const ApiCategoryInsight({
    required this.category,
    required this.accuracy,
    required this.activitiesCompleted,
    required this.status,
    required this.recommendedDifficulty,
    required this.message,
  });

  factory ApiCategoryInsight.fromJson(Map<String, dynamic> json) =>
      ApiCategoryInsight(
        category: json['category'] as String? ?? '',
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        activitiesCompleted: json['activities_completed'] as int? ?? 0,
        status: json['status'] as String? ?? '',
        recommendedDifficulty: json['recommended_difficulty'] as int? ?? 1,
        message: json['message'] as String? ?? '',
      );
}
