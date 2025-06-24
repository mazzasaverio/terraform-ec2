from sqlalchemy import Column, String, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from .base import Base
import uuid

class Bookmark(Base):
    __tablename__ = "bookmarks"
    
    id = Column(String(255), primary_key=True, default=lambda: str(uuid.uuid4()))
    userId = Column(String(255), ForeignKey("user.userId", ondelete="CASCADE"), nullable=False)
    postId = Column(String(255), ForeignKey("posts.postId", ondelete="CASCADE"), nullable=False)
    createdAt = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="bookmarks")
    post = relationship("Post", back_populates="bookmarks")
    
    # Unique constraint
    __table_args__ = (UniqueConstraint('userId', 'postId', name='uq_user_post_bookmark'),)
    
    def __repr__(self):
        return f"<Bookmark(id={self.id}, userId='{self.userId}', postId='{self.postId}')>" 