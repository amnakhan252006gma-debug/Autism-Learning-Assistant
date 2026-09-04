from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

from database import Base


class Progress(Base):
    __tablename__ = "progress"

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

    category = Column(
        String,
        nullable=False
    )

    accuracy = Column(
        Float,
        nullable=False,
        default=0
    )

    score = Column(
        Float,
        nullable=False,
        default=0
    )

    activities_completed = Column(
        Integer,
        nullable=False,
        default=0
    )

    current_difficulty = Column(
        Integer,
        nullable=False,
        default=1
    )

    updated_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    child = relationship(
        "Child",
        backref="progress"
    )