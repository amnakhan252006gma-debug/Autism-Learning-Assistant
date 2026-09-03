from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from database import SessionLocal
from models import ActivityResult, Child, Activity, User
from routes.auth import get_current_user
from services.authorization import get_authorized_child
from services.progress_service import update_child_progress


router = APIRouter(
    prefix="/activity-results",
    tags=["Activity Results"]
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class ActivityResultCreate(BaseModel):
    child_id: int
    activity_id: int
    difficulty: int = Field(..., ge=1, le=3)
    score: float = Field(..., ge=0)
    correct_answers: int = Field(..., ge=0)
    incorrect_answers: int = Field(..., ge=0)
    attempts: int = Field(..., ge=0)
    time_taken: float | None = Field(
        default=None,
        ge=0
    )
    completion_status: str


@router.post("/")
def create_activity_result(
    result_data: ActivityResultCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    get_authorized_child(
        child_id=result_data.child_id,
        current_user=current_user,
        db=db
    )

    activity = (
        db.query(Activity)
        .filter(Activity.id == result_data.activity_id)
        .first()
    )

    if not activity:
        raise HTTPException(
            status_code=404,
            detail="Activity not found."
        )

    result = ActivityResult(
        child_id=result_data.child_id,
        activity_id=result_data.activity_id,
        difficulty=result_data.difficulty,
        score=result_data.score,
        correct_answers=result_data.correct_answers,
        incorrect_answers=result_data.incorrect_answers,
        attempts=result_data.attempts,
        time_taken=result_data.time_taken,
        completion_status=result_data.completion_status
    )

    db.add(result)
    db.commit()
    db.refresh(result)

    progress = update_child_progress(
        child_id=result_data.child_id,
        activity_id=result_data.activity_id,
        db=db
    )

    return {
        "message": "Activity result saved successfully",
        "result": result,
        "progress": progress
    }


@router.get("/child/{child_id}")
def get_child_results(
    child_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    get_authorized_child(
        child_id=child_id,
        current_user=current_user,
        db=db
    )

    return (
        db.query(ActivityResult)
        .filter(
            ActivityResult.child_id == child_id
        )
        .all()
    )