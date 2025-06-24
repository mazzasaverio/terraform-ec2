from sqlalchemy import Column, String, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from .base import Base

class Like(Base):
    __tablename__ = "likes"
    
    userId = Column(String(255), ForeignKey("user.userId", ondelete="CASCADE"), primary_key=True)
    postId = Column(String(255), ForeignKey("posts.postId", ondelete="CASCADE"), primary_key=True)
    
    # Relationships
    user = relationship("User", back_populates="likes")
    post = relationship("Post", back_populates="likes")
    
    # Unique constraint
    __table_args__ = (UniqueConstraint('userId', 'postId', name='uq_user_post_like'),)
    
    def __repr__(self):
        return f"<Like(userId='{self.userId}', postId='{self.postId}')>" 