from datetime import datetime, timezone

from sqlalchemy.orm import Session

from models import ActivityResult, Activity, Progress


def update_child_progress(
    child_id: int,
    activity_id: int,
    db: Session
):
    """
    Recalculate and update progress for one child
    in the category of the completed activity.
    """

    # --------------------------------------------------
    # 1. Find the activity
    # --------------------------------------------------

    activity = (
        db.query(Activity)
        .filter(Activity.id == activity_id)
        .first()
    )

    if not activity:
        return None

    category = activity.category

    # --------------------------------------------------
    # 2. Get all results for this child + category
    # --------------------------------------------------

    results = (
        db.query(ActivityResult)
        .join(
            Activity,
            ActivityResult.activity_id == Activity.id
        )
        .filter(
            ActivityResult.child_id == child_id,
            Activity.category == category
        )
        .order_by(ActivityResult.created_at.asc())
        .all()
    )

    if not results:
        return None

    # --------------------------------------------------
    # 3. Calculate total correct / incorrect answers
    # --------------------------------------------------

    total_correct = sum(
        result.correct_answers
        for result in results
    )

    total_incorrect = sum(
        result.incorrect_answers
        for result in results
    )

    total_answers = (
        total_correct + total_incorrect
    )

    # --------------------------------------------------
    # 4. Calculate overall category accuracy
    # --------------------------------------------------

    if total_answers > 0:
        accuracy = (
            total_correct / total_answers
        ) * 100
    else:
        accuracy = 0.0

    # --------------------------------------------------
    # 5. Calculate average score
    # --------------------------------------------------

    total_score = sum(
        result.score
        for result in results
    )

    average_score = (
        total_score / len(results)
    )

    # --------------------------------------------------
    # 6. Get the latest difficulty played
    # --------------------------------------------------

    latest_result = results[-1]

    current_difficulty = latest_result.difficulty

    # --------------------------------------------------
    # 7. Find existing progress record
    # --------------------------------------------------

    progress = (
        db.query(Progress)
        .filter(
            Progress.child_id == child_id,
            Progress.category == category
        )
        .first()
    )

    # --------------------------------------------------
    # 8. Create progress if it doesn't exist
    # --------------------------------------------------

    if not progress:

        progress = Progress(
            child_id=child_id,
            category=category,
            accuracy=accuracy,
            score=average_score,
            activities_completed=len(results),
            current_difficulty=current_difficulty,
            updated_at=datetime.now(timezone.utc)
        )

        db.add(progress)

    # --------------------------------------------------
    # 9. Update existing progress
    # --------------------------------------------------

    else:

        progress.accuracy = accuracy

        progress.score = average_score

        progress.activities_completed = len(results)

        progress.current_difficulty = current_difficulty

        progress.updated_at = datetime.now(timezone.utc)

    # --------------------------------------------------
    # 10. Save changes
    # --------------------------------------------------

    db.commit()
    db.refresh(progress)

    return progress