from sqlalchemy import Column, String, DateTime, ForeignKey, Float, Boolean, ARRAY, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from .base import Base
import uuid

class Post(Base):
    __tablename__ = "posts"
    
    id = Column(String(255), primary_key=True, default=lambda: str(uuid.uuid4()))
    postId = Column(String(255), unique=True, nullable=False)
    url = Column(String(1000), nullable=True)
    title = Column(String(500), nullable=True)
    description = Column(Text, nullable=True)
    content = Column(Text, nullable=True)
    section = Column(String(200), nullable=True)
    types = Column(ARRAY(String), nullable=False, default=[])
    categories = Column(ARRAY(String), nullable=False, default=[])
    tags = Column(ARRAY(String), nullable=False, default=[])
    score = Column(Float, nullable=False)
    generationText = Column(Text, nullable=True)
    generationUrl = Column(String(1000), nullable=True)
    isPublic = Column(Boolean, default=True, nullable=False)
    createdAt = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Foreign key relationship
    userId = Column(String(255), ForeignKey("user.userId", ondelete="CASCADE"), nullable=False)
    user = relationship("User", back_populates="posts")
    
    # Relationships
    likes = relationship("Like", back_populates="post", cascade="all, delete-orphan")
    bookmarks = relationship("Bookmark", back_populates="post", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Post(id={self.id}, postId='{self.postId}', title='{self.title}')>" 