
def calculate_next_difficulty(
    accuracy: float,
    current_difficulty: int,
    minimum_level: int = 1,
    maximum_level: int = 3
):
    """
    Decide the child's next difficulty level
    based on their accuracy.
    """

    if accuracy < 50:
        next_difficulty = current_difficulty - 1
    elif accuracy >= 80:
        next_difficulty = current_difficulty + 1
    else:
        next_difficulty = current_difficulty

    # Never go below the minimum level
    if next_difficulty < minimum_level:
        next_difficulty = minimum_level

    # Never go above the maximum level
    if next_difficulty > maximum_level:
        next_difficulty = maximum_level

    if accuracy < 50:
        reason = "The child is struggling, so an easier level is recommended."
    elif accuracy >= 80:
        reason = "The child is performing well, so a harder level is recommended."
    else:
        reason = "The child is performing at a moderate level, so the current difficulty is maintained."

    return {
        "current_difficulty": current_difficulty,
        "next_difficulty": next_difficulty,
        "accuracy": round(accuracy, 2),
        "reason": reason
    }


def determine_difficulty(analysis: dict):
    """
    Determine the recommended difficulty level
    for each category based on the child's performance.
    """

    difficulty_recommendations = {}

    category_performance = analysis.get(
        "category_performance",
        {}
    )

    for category, data in category_performance.items():

        accuracy = data.get(
            "accuracy",
            0
        )

        # Start every category at difficulty level 1
        current_difficulty = 1

        difficulty_recommendations[category] = calculate_next_difficulty(
            accuracy=accuracy,
            current_difficulty=current_difficulty
        )

    return difficulty_recommendations


if __name__ == "__main__":

    print(
        calculate_next_difficulty(
            accuracy=90,
            current_difficulty=1
        )
    )

    print(
        calculate_next_difficulty(
            accuracy=40,
            current_difficulty=2
        )
    )

    print(
        calculate_next_difficulty(
            accuracy=65,
            current_difficulty=2
        )
    )

