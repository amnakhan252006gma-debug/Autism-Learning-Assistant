from sqlalchemy.orm import Session
from models import ActivityResult, Activity


def analyze_child_performance(
    child_id: int,
    db: Session
):
    results = (
        db.query(ActivityResult, Activity)
        .join(
            Activity,
            ActivityResult.activity_id == Activity.id
        )
        .filter(ActivityResult.child_id == child_id)
        .all()
    )

    if not results:
       return {
    "child_id": child_id,
    "overall_accuracy": 0,
    "category_performance": {},
    "strengths": [],
    "weak_areas": [],
    "message": "Not enough activity data yet."
}

    category_data = {}

    total_correct = 0
    total_questions = 0

    for result, activity in results:

        category = activity.category

        if category not in category_data:
            category_data[category] = {
                "correct": 0,
                "incorrect": 0,
                "activities": 0
            }

        category_data[category]["correct"] += result.correct_answers
        category_data[category]["incorrect"] += result.incorrect_answers
        category_data[category]["activities"] += 1

        total_correct += result.correct_answers
        total_questions += (
            result.correct_answers
            + result.incorrect_answers
        )

    # Overall accuracy
    if total_questions > 0:
        overall_accuracy = (
            total_correct / total_questions
        ) * 100
    else:
        overall_accuracy = 0

    strengths = []
    weak_areas = []

    category_performance = {}

    for category, data in category_data.items():

        category_total = (
            data["correct"] +
            data["incorrect"]
        )

        if category_total > 0:
            accuracy = (
                data["correct"] /
                category_total
            ) * 100
        else:
            accuracy = 0

        category_performance[category] = {
            "accuracy": round(accuracy, 2),
            "activities_completed": data["activities"]
        }

        if accuracy >= 80:
            strengths.append(category)

        elif accuracy < 60:
            weak_areas.append(category)

    return {
        "child_id": child_id,
        "overall_accuracy": round(
            overall_accuracy,
            2
        ),
        "category_performance": category_performance,
        "strengths": strengths,
        "weak_areas": weak_areas
    }