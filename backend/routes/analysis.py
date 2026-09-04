from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import SessionLocal
from models import Child, User, Progress
from routes.auth import get_current_user
from services.authorization import get_authorized_child

from services.performance_analyzer import analyze_child_performance
from services.difficulty_engine import calculate_next_difficulty
from services.recommendation_engine import generate_recommendations
from services.ai_insights import generate_ai_insight


router = APIRouter(
    prefix="/analysis",
    tags=["Analysis"]
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.get("/child/{child_id}")
def get_child_analysis(
    child_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    get_authorized_child(
        child_id=child_id,
        current_user=current_user,
        db=db
    )

    analysis = analyze_child_performance(
        child_id=child_id,
        db=db
    )

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

        progress = (
            db.query(Progress)
            .filter(
                Progress.child_id == child_id,
                Progress.category == category
            )
            .first()
        )

        if progress:
            current_difficulty = progress.current_difficulty
        else:
            current_difficulty = 1

        difficulty_recommendations[category] = (
            calculate_next_difficulty(
                accuracy=accuracy,
                current_difficulty=current_difficulty
            )
        )

    recommendations = generate_recommendations(
        analysis=analysis,
        difficulty_recommendations=difficulty_recommendations
    )

    ai_insight = generate_ai_insight(
        analysis=analysis,
        difficulty_recommendations=difficulty_recommendations,
        recommendations=recommendations
    )

    return {
        "child_id": child_id,
        "performance": analysis,
        "difficulty": difficulty_recommendations,
        "recommendations": recommendations,
        "ai_insight": ai_insight
    }