from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

from database import Base


class ActivityResult(Base):
    __tablename__ = "activity_results"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    child_id = Column(
        Integer,
        ForeignKey("children.id"),
        nullable=False
    )

    activity_id = Column(
        Integer,
        ForeignKey("activities.id"),
        nullable=False
    )

    difficulty = Column(
        Integer,
        nullable=False
    )

    score = Column(
        Float,
        nullable=False
    )

    correct_answers = Column(
        Integer,
        nullable=False,
        default=0
    )

    incorrect_answers = Column(
        Integer,
        nullable=False,
        default=0
    )

    attempts = Column(
        Integer,
        nullable=False,
        default=0
    )

    time_taken = Column(
        Float,
        nullable=True
    )

    completion_status = Column(
        String,
        nullable=False
    )

    created_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    child = relationship(
        "Child",
        backref="activity_results"
    )

    activity = relationship(
        "Activity",
        backref="activity_results"
    )