from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text
from sqlalchemy.sql import func
from .base import Base

class Message(Base):
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True, index=True)
    message = Column(Text, nullable=False)
    user_id = Column(String(255), nullable=False, index=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    processed = Column(Boolean, default=True, nullable=False)
    
    def __repr__(self):
        return f"<Message(id={self.id}, user_id='{self.user_id}', message='{self.message[:50]}...')>" 