from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import SessionLocal
from models import Child
from routes.auth import get_current_user
from models import User


router = APIRouter(
    prefix="/children",
    tags=["Children"]
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class ChildCreate(BaseModel):
    name: str
    age: int
    avatar: str | None = None
    learning_preferences: str | None = None


class ChildUpdate(BaseModel):
    name: str | None = None
    age: int | None = None
    avatar: str | None = None
    learning_preferences: str | None = None


@router.post("/")
def create_child(
    child_data: ChildCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "parent":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only parents can create children"
        )

    child = Child(
        parent_id=current_user.id,
        name=child_data.name,
        age=child_data.age,
        avatar=child_data.avatar,
        learning_preferences=child_data.learning_preferences
    )

    db.add(child)
    db.commit()
    db.refresh(child)

    return child


@router.get("/")
def get_children(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "parent":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only parents can access children"
        )

    return (
        db.query(Child)
        .filter(Child.parent_id == current_user.id)
        .all()
    )


@router.get("/{child_id}")
def get_child(
    child_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    child = (
        db.query(Child)
        .filter(
            Child.id == child_id,
            Child.parent_id == current_user.id
        )
        .first()
    )

    if not child:
        raise HTTPException(
            status_code=404,
            detail="Child not found"
        )

    return child


@router.put("/{child_id}")
def update_child(
    child_id: int,
    child_data: ChildUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    child = (
        db.query(Child)
        .filter(
            Child.id == child_id,
            Child.parent_id == current_user.id
        )
        .first()
    )

    if not child:
        raise HTTPException(
            status_code=404,
            detail="Child not found"
        )

    if child_data.name is not None:
        child.name = child_data.name

    if child_data.age is not None:
        child.age = child_data.age

    if child_data.avatar is not None:
        child.avatar = child_data.avatar

    if child_data.learning_preferences is not None:
        child.learning_preferences = child_data.learning_preferences

    db.commit()
    db.refresh(child)

    return child


@router.delete("/{child_id}")
def delete_child(
    child_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    child = (
        db.query(Child)
        .filter(
            Child.id == child_id,
            Child.parent_id == current_user.id
        )
        .first()
    )

    if not child:
        raise HTTPException(
            status_code=404,
            detail="Child not found"
        )

    db.delete(child)
    db.commit()

    return {
        "message": "Child deleted successfully"
    }