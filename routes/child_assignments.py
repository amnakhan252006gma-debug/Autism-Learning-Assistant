from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from database import SessionLocal
from models import ChildAssignment, Child, User
from routes.auth import get_current_user

router = APIRouter(
    prefix="/assignments",
    tags=["Assignments"]
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class ChildAssignmentCreate(BaseModel):
    child_id: int
    user_id: int
    role: str

@router.post("/")
def create_assignment(
    assignment_data: ChildAssignmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "parent":
        raise HTTPException(
            status_code=403,
            detail="Only parents can create child assignments."
        )

    role = assignment_data.role.lower()

    if role not in ["teacher", "therapist"]:
        raise HTTPException(
            status_code=400,
            detail="Role must be either teacher or therapist."
        )

    child = (
        db.query(Child)
        .filter(
            Child.id == assignment_data.child_id,
            Child.parent_id == current_user.id
        )
        .first()
    )

    if not child:
        raise HTTPException(
            status_code=403,
            detail="You can only assign users to your own children."
        )

    assigned_user = (
        db.query(User)
        .filter(User.id == assignment_data.user_id)
        .first()
    )

    if not assigned_user:
        raise HTTPException(
            status_code=404,
            detail="User not found."
        )

    if assigned_user.role != role:
        raise HTTPException(
            status_code=400,
            detail="User role does not match the assignment role."
        )

    existing_assignment = (
        db.query(ChildAssignment)
        .filter(
            ChildAssignment.child_id == assignment_data.child_id,
            ChildAssignment.user_id == assignment_data.user_id
        )
        .first()
    )

    if existing_assignment:
        raise HTTPException(
            status_code=400,
            detail="This user is already assigned to this child."
        )

    assignment = ChildAssignment(
        child_id=assignment_data.child_id,
        user_id=assignment_data.user_id,
        role=role
    )

    db.add(assignment)
    db.commit()
    db.refresh(assignment)

    return assignment


@router.get("/child/{child_id}")
def get_child_assignments(
    child_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    child = (
        db.query(Child)
        .filter(Child.id == child_id)
        .first()
    )

    if not child:
        raise HTTPException(
            status_code=404,
            detail="Child not found."
        )

    if (
        current_user.role == "parent"
        and child.parent_id == current_user.id
    ):
        return (
            db.query(ChildAssignment)
            .filter(
                ChildAssignment.child_id == child_id
            )
            .all()
        )

    if current_user.role in ["teacher", "therapist"]:
        assignment = (
            db.query(ChildAssignment)
            .filter(
                ChildAssignment.child_id == child_id,
                ChildAssignment.user_id == current_user.id,
                ChildAssignment.role == current_user.role
            )
            .first()
        )

        if assignment:
            return [assignment]

    raise HTTPException(
        status_code=403,
        detail="Access denied."
    )


@router.get("/user/{user_id}")
def get_user_assignments(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.id != user_id:
        raise HTTPException(
            status_code=403,
            detail="You can only view your own assignments."
        )

    return (
        db.query(ChildAssignment)
        .filter(
            ChildAssignment.user_id == user_id
        )
        .all()
    )


@router.delete("/{assignment_id}")
def delete_assignment(
    assignment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    assignment = (
        db.query(ChildAssignment)
        .filter(
            ChildAssignment.id == assignment_id
        )
        .first()
    )

    if not assignment:
        raise HTTPException(
            status_code=404,
            detail="Assignment not found."
        )

    child = (
        db.query(Child)
        .filter(Child.id == assignment.child_id)
        .first()
    )

    if not child:
        raise HTTPException(
            status_code=404,
            detail="Child not found."
        )

    if (
        current_user.role != "parent"
        or child.parent_id != current_user.id
    ):
        raise HTTPException(
            status_code=403,
            detail="Only the child's parent can remove this assignment."
        )

    db.delete(assignment)
    db.commit()

    return {
        "message": "Assignment deleted successfully."
    }