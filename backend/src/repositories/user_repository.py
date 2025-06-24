from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional
from passlib.context import CryptContext
import uuid

from src.models.user import User

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserRepository:
    def __init__(self, session: AsyncSession):
        self.session = session
    
    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        """Verify a password against its hash"""
        return pwd_context.verify(plain_password, hashed_password)
    
    @staticmethod
    def get_password_hash(password: str) -> str:
        """Hash a password"""
        return pwd_context.hash(password)
    
    async def get_by_user_id(self, user_id: str) -> Optional[User]:
        """Get user by userId"""
        result = await self.session.execute(
            select(User).where(User.userId == user_id)
        )
        return result.scalar_one_or_none()
    
    async def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email"""
        result = await self.session.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()
    
    async def create(self, user_id: str, email: str = None, avatar_url: str = None) -> User:
        """Create a new user"""
        user = User(
            userId=user_id,
            email=email,
            avatar_url=avatar_url
        )
        self.session.add(user)
        await self.session.commit()
        await self.session.refresh(user)
        return user
    
    async def authenticate(self, user_id: str) -> Optional[User]:
        """Get user by userId (for authentication)"""
        user = await self.get_by_user_id(user_id)
        return user 