from sqlalchemy import Column, Integer, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

from database import Base


class ActivityAttempt(Base):
    __tablename__ = "activity_attempts"

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

    correct = Column(
        Boolean,
        nullable=False
    )

    response_time = Column(
        Float,
        nullable=True
    )

    attempt_number = Column(
        Integer,
        nullable=False,
        default=1
    )

    created_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    child = relationship(
        "Child",
        backref="activity_attempts"
    )

    activity = relationship(
        "Activity",
        backref="activity_attempts"
    )
    