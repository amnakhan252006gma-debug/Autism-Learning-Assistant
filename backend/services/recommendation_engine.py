def generate_recommendations(
    analysis: dict,
    difficulty_recommendations: dict
):
    recommendations = []

    weak_areas = analysis.get(
        "weak_areas",
        []
    )

    strengths = analysis.get(
        "strengths",
        []
    )

    category_performance = analysis.get(
        "category_performance",
        {}
    )

    # Recommend weak areas first
    for category in weak_areas:

        difficulty_info = difficulty_recommendations.get(
            category,
            {}
        )

        recommendations.append({
            "category": category,
            "difficulty": difficulty_info.get(
                "next_difficulty",
                1
            ),
            "priority": "high",
            "reason": (
                f"More practice is recommended "
                f"in {category}."
            )
        })

    # If there are no weak areas,
    # recommend activities in strong areas
    if not recommendations:

        for category in strengths:

            difficulty_info = difficulty_recommendations.get(
                category,
                {}
            )

            recommendations.append({
                "category": category,
                "difficulty": difficulty_info.get(
                    "next_difficulty",
                    1
                ),
                "priority": "medium",
                "reason": (
                    f"The child is performing well "
                    f"in {category}. A more challenging "
                    f"activity is recommended."
                )
            })

    # If there isn't enough data
    if not recommendations:

        for category in category_performance:

            recommendations.append({
                "category": category,
                "difficulty": 1,
                "priority": "medium",
                "reason": (
                    "Continue practicing to build "
                    "more performance data."
                )
            })

    return recommendations