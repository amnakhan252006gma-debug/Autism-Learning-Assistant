
def generate_ai_insight(
    analysis: dict,
    difficulty_recommendations: dict,
    recommendations: list
):
    """
    Generate a parent-friendly AI insight based on
    the child's performance, difficulty and recommendations.
    """

    overall_accuracy = analysis.get(
        "overall_accuracy",
        0
    )

    strengths = analysis.get(
        "strengths",
        []
    )

    weak_areas = analysis.get(
        "weak_areas",
        []
    )

    category_performance = analysis.get(
        "category_performance",
        {}
    )

    # --------------------------------------------------
    # 1. Determine overall status
    # --------------------------------------------------

    if overall_accuracy >= 80:
        overall_status = "Excellent Progress"
    elif overall_accuracy >= 60:
        overall_status = "Good Progress"
    elif overall_accuracy >= 50:
        overall_status = "Needs More Practice"
    else:
        overall_status = "Needs Support"

    # --------------------------------------------------
    # 2. Generate summary
    # --------------------------------------------------

    if not category_performance:
        summary = (
            "There is not enough activity data yet "
            "to provide a detailed performance insight."
        )

    elif overall_accuracy >= 80:
        summary = (
            f"The child is performing very well overall "
            f"with an accuracy of {overall_accuracy}%. "
            f"The current performance suggests that the "
            f"child is ready for more challenging activities."
        )

    elif overall_accuracy >= 60:
        summary = (
            f"The child is making good progress with an "
            f"overall accuracy of {overall_accuracy}%. "
            f"Continued practice can help strengthen "
            f"learning and improve consistency."
        )

    elif overall_accuracy >= 50:
        summary = (
            f"The child currently has an overall accuracy "
            f"of {overall_accuracy}%. More practice is "
            f"recommended to strengthen learning and "
            f"build confidence."
        )

    else:
        summary = (
            f"The child currently has an overall accuracy "
            f"of {overall_accuracy}%. The child may benefit "
            f"from additional support and easier activities "
            f"before progressing to higher difficulty levels."
        )

    # --------------------------------------------------
    # 3. Generate parent advice
    # --------------------------------------------------

    if weak_areas:
        weak_area_text = ", ".join(weak_areas)

        parent_advice = (
            f"Focus additional practice on {weak_area_text}. "
            f"Start with manageable activities and gradually "
            f"increase difficulty as the child's accuracy improves."
        )

    elif strengths:
        strength_text = ", ".join(strengths)

        parent_advice = (
            f"The child is showing strong performance in "
            f"{strength_text}. Continue encouraging practice "
            f"and gradually introduce more challenging activities."
        )

    else:
        parent_advice = (
            "Continue regular practice so that more performance "
            "data can be collected and better personalized "
            "recommendations can be provided."
        )

    # --------------------------------------------------
    # 4. Generate category insights
    # --------------------------------------------------

    category_insights = []

    for category, data in category_performance.items():

        accuracy = data.get(
            "accuracy",
            0
        )

        activities_completed = data.get(
            "activities_completed",
            0
        )

        difficulty_info = difficulty_recommendations.get(
            category,
            {}
        )

        next_difficulty = difficulty_info.get(
            "next_difficulty",
            1
        )

        if accuracy >= 80:
            status = "Strong"

            message = (
                f"The child is performing strongly in {category} "
                f"with {accuracy}% accuracy. "
                f"Consider activities at difficulty level "
                f"{next_difficulty}."
            )

        elif accuracy >= 60:
            status = "Developing"

            message = (
                f"The child is developing skills in {category} "
                f"with {accuracy}% accuracy. "
                f"Continue regular practice at difficulty level "
                f"{next_difficulty}."
            )

        else:
            status = "Needs Practice"

            message = (
                f"The child needs additional practice in {category} "
                f"with {accuracy}% accuracy. "
                f"Use supportive activities at difficulty level "
                f"{next_difficulty}."
            )

        category_insights.append({
            "category": category,
            "accuracy": accuracy,
            "activities_completed": activities_completed,
            "status": status,
            "recommended_difficulty": next_difficulty,
            "message": message
        })

    # --------------------------------------------------
    # 5. Return AI insight
    # --------------------------------------------------

    return {
        "overall_status": overall_status,
        "summary": summary,
        "strengths": strengths,
        "areas_to_improve": weak_areas,
        "parent_advice": parent_advice,
        "category_insights": category_insights
    }
