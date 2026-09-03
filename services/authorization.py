from fastapi import HTTPException
from sqlalchemy.orm import Session

from models import Child, ChildAssignment, User


def get_authorized_child(
    child_id: int,
    current_user: User,
    db: Session
):
    """
    Check whether the current user is allowed to access a child.

    Parent:
        Can access their own children.

    Teacher:
        Can access children assigned to them.

    Therapist:
        Can access children assigned to them.

    Everyone else:
        Access denied.
    """

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

    # Parent owns the child
    if (
        current_user.role == "parent"
        and child.parent_id == current_user.id
    ):
        return child

    # Teacher or therapist must have an assignment
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
            return child

    raise HTTPException(
        status_code=403,
        detail="Access denied: You are not authorized to access this child's data."
    )