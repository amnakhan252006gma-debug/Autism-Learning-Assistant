from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship

from database import Base


class Child(Base):
    __tablename__ = "children"

    id = Column(Integer, primary_key=True, index=True)

    parent_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    name = Column(String, nullable=False)

    age = Column(Integer, nullable=False)

    avatar = Column(String, nullable=True)

    learning_preferences = Column(
        String,
        nullable=True
    )

    created_at = Column(
        String,
        nullable=True
    )

    parent = relationship(
        "User",
        backref="children"
    )