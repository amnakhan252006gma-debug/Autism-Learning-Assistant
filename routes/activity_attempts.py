from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from database import SessionLocal
from models import ActivityAttempt, Child, Activity, User
from routes.auth import get_current_user
from services.authorization import get_authorized_child


router = APIRouter(
    prefix="/activity-attempts",
    tags=["Activity Attempts"]
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class ActivityAttemptCreate(BaseModel):
    child_id: int
    activity_id: int
    difficulty: int = Field(..., ge=1, le=3)
    correct: bool
    response_time: float | None = Field(
        default=None,
        ge=0
    )
    attempt_number: int = Field(
        default=1,
        ge=1
    )


@router.post("/")
def create_activity_attempt(
    attempt_data: ActivityAttemptCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    get_authorized_child(
        child_id=attempt_data.child_id,
        current_user=current_user,
        db=db
    )

    activity = (
        db.query(Activity)
        .filter(Activity.id == attempt_data.activity_id)
        .first()
    )

    if not activity:
        raise HTTPException(
            status_code=404,
            detail="Activity not found."
        )

    attempt = ActivityAttempt(
        child_id=attempt_data.child_id,
        activity_id=attempt_data.activity_id,
        difficulty=attempt_data.difficulty,
        correct=attempt_data.correct,
        response_time=attempt_data.response_time,
        attempt_number=attempt_data.attempt_number
    )

    db.add(attempt)
    db.commit()
    db.refresh(attempt)

    return attempt


@router.get("/child/{child_id}")
def get_child_attempts(
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
        db.query(ActivityAttempt)
        .filter(
            ActivityAttempt.child_id == child_id
        )
        .all()
    )