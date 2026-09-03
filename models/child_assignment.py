from sqlalchemy import Column, Integer, String, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from database import Base


class ChildAssignment(Base):
    __tablename__ = "child_assignments"

    __table_args__ = (
        UniqueConstraint(
            "child_id",
            "user_id",
            name="uq_child_user_assignment"
        ),
    )

    id = Column(Integer, primary_key=True, index=True)

    child_id = Column(
        Integer,
        ForeignKey("children.id"),
        nullable=False
    )

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    role = Column(
        String,
        nullable=False
    )

    child = relationship(
        "Child",
        backref="assignments"
    )

    user = relationship(
        "User",
        backref="child_assignments"
    )