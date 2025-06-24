from sqlalchemy import Column, String, DateTime, Integer, ARRAY, JSON, Index
from sqlalchemy.sql import func
from .base import Base
import uuid

class UrlBookmark(Base):
    __tablename__ = "url_bookmarks"
    
    id = Column(String(255), primary_key=True, default=lambda: str(uuid.uuid4()))
    userId = Column(String(255), nullable=False)
    url = Column(String(1000), nullable=False)
    title = Column(String(500), nullable=False)
    description = Column(String(1000), nullable=False)
    categories = Column(ARRAY(String), nullable=False, default=[])
    types = Column(ARRAY(String), nullable=False, default=[])
    score = Column(Integer, nullable=False)
    insights = Column(JSON, nullable=True)
    analysis = Column(JSON, nullable=True)
    createdAt = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updatedAt = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Index on categories
    __table_args__ = (Index('idx_url_bookmarks_categories', 'categories'),)
    
    def __repr__(self):
        return f"<UrlBookmark(id={self.id}, userId='{self.userId}', title='{self.title}')>" 