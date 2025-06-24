from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime

from src.models.message import Message
from src.utils.database import get_db_session

class MessageRepository:
    def __init__(self, session: AsyncSession):
        self.session = session
    
    async def create(self, message: str, user_id: str, processed: bool = True) -> Message:
        """Create a new message"""
        db_message = Message(
            message=message,
            user_id=user_id,
            timestamp=datetime.now(),
            processed=processed
        )
        self.session.add(db_message)
        await self.session.commit()
        await self.session.refresh(db_message)
        return db_message
    
    async def get_by_id(self, message_id: int) -> Optional[Message]:
        """Get message by ID"""
        result = await self.session.execute(
            select(Message).where(Message.id == message_id)
        )
        return result.scalar_one_or_none()
    
    async def get_all(self) -> List[Message]:
        """Get all messages"""
        result = await self.session.execute(select(Message).order_by(Message.timestamp.desc()))
        return result.scalars().all()
    
    async def get_by_user_id(self, user_id: str) -> List[Message]:
        """Get messages by user ID"""
        result = await self.session.execute(
            select(Message).where(Message.user_id == user_id).order_by(Message.timestamp.desc())
        )
        return result.scalars().all()
    
    async def delete(self, message_id: int) -> bool:
        """Delete message by ID"""
        result = await self.session.execute(
            delete(Message).where(Message.id == message_id)
        )
        await self.session.commit()
        return result.rowcount > 0
    
    async def update(self, message_id: int, **kwargs) -> Optional[Message]:
        """Update message"""
        message = await self.get_by_id(message_id)
        if not message:
            return None
        
        for key, value in kwargs.items():
            if hasattr(message, key):
                setattr(message, key, value)
        
        await self.session.commit()
        await self.session.refresh(message)
        return message 