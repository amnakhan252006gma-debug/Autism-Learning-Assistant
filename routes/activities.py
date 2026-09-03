from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from database import SessionLocal
from models import Activity
from routes.auth import get_current_user
from models import User


router = APIRouter(
    prefix="/activities",
    tags=["Activities"]
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class ActivityCreate(BaseModel):
    name: str
    category: str
    description: str | None = None
    difficulty: int = Field(default=1, ge=1, le=3)

@router.post("/")
def create_activity(
    activity_data: ActivityCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["teacher", "therapist"]:
        raise HTTPException(
            status_code=403,
            detail="Only teachers and therapists can create activities"
        )

    activity = Activity(
        name=activity_data.name,
        category=activity_data.category,
        description=activity_data.description,
        difficulty=activity_data.difficulty
    )

    db.add(activity)
    db.commit()
    db.refresh(activity)

    return activity


@router.get("/")
def get_activities(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(Activity).all()


@router.get("/{activity_id}")
def get_activity(
    activity_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    activity = (
        db.query(Activity)
        .filter(Activity.id == activity_id)
        .first()
    )

    if not activity:
        raise HTTPException(
            status_code=404,
            detail="Activity not found"
        )

    return activity