import 'api_recommendation_shared.dart';

/// Backend-aligned recommendations response.
///
/// Mirrors the payload returned by FastAPI
/// `GET /recommendations/child/{child_id}`:
/// child_id, difficulty, recommendations.
class ApiRecommendationResponse {
  final int childId;
  final Map<String, ApiDifficultyDecision> difficulty;
  final List<ApiRecommendationItem> recommendations;

  const ApiRecommendationResponse({
    required this.childId,
    required this.difficulty,
    required this.recommendations,
  });

  factory ApiRecommendationResponse.fromJson(Map<String, dynamic> json) =>
      ApiRecommendationResponse(
        childId: json['child_id'] as int,
        difficulty:
            (json['difficulty'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                ApiDifficultyDecision.fromJson(value as Map<String, dynamic>),
              ),
            ),
        recommendations:
            (json['recommendations'] as List)
                .map(
                  (e) =>
                      ApiRecommendationItem.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
      );
}
