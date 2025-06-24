from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from .base import Base
import uuid

class Feedback(Base):
    __tablename__ = "feedback"
    
    id = Column(String(255), primary_key=True, default=lambda: str(uuid.uuid4()))
    type = Column(String(100), nullable=False)
    description = Column(String(1000), nullable=False)
    createdAt = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updatedAt = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Foreign key relationship
    userId = Column(String(255), ForeignKey("user.userId"), nullable=False, index=True)
    user = relationship("User", back_populates="feedback")
    
    def __repr__(self):
        return f"<Feedback(id={self.id}, type='{self.type}', userId='{self.userId}')>" 