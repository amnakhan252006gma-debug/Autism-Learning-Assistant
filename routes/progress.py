from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import SessionLocal
from models import Progress, User
from routes.auth import get_current_user
from services.authorization import get_authorized_child


router = APIRouter(
    prefix="/progress",
    tags=["Progress"]
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.get("/child/{child_id}")
def get_child_progress(
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
        db.query(Progress)
        .filter(
            Progress.child_id == child_id
        )
        .all()
    )