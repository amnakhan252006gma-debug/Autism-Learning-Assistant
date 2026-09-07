from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import SessionLocal
from models import User
from routes.auth import get_current_user

router = APIRouter(
    prefix="/users",
    tags=["Users"],
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.get("/staff")
def get_staff_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Parents can retrieve available teachers and therapists
    so they can assign them to their children.
    """

    if current_user.role != "parent":
        raise HTTPException(
            status_code=403,
            detail="Only parents can view available teachers and therapists.",
        )

    users = (
        db.query(User)
        .filter(User.role.in_(["teacher", "therapist"]))
        .order_by(User.role, User.name)
        .all()
    )

    return [
        {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "role": user.role,
        }
        for user in users
    ]