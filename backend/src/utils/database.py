import os
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import MetaData, text
from contextlib import asynccontextmanager
from typing import AsyncGenerator
import logging
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse

logger = logging.getLogger(__name__)

# Base class for SQLAlchemy models
Base = declarative_base()

# Database configuration
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    # Default to local PostgreSQL
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_NAME = os.getenv("DB_NAME", "simple_backend")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
    
    DATABASE_URL = f"postgresql+asyncpg://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Convert standard PostgreSQL URL to asyncpg format and handle SSL parameters
if DATABASE_URL.startswith("postgresql://") and not DATABASE_URL.startswith("postgresql+asyncpg://"):
    # Parse the URL
    parsed = urlparse(DATABASE_URL)
    query_params = parse_qs(parsed.query)
    
    # Remove sslmode from query parameters as it's handled differently by asyncpg
    if 'sslmode' in query_params:
        del query_params['sslmode']
    
    # Rebuild the URL without sslmode in query
    new_query = urlencode(query_params, doseq=True) if query_params else ""
    new_parsed = parsed._replace(
        scheme="postgresql+asyncpg",
        query=new_query
    )
    DATABASE_URL = urlunparse(new_parsed)

# Create async engine with SSL configuration
engine = create_async_engine(
    DATABASE_URL,
    echo=os.getenv("DB_ECHO", "false").lower() == "true",
    pool_pre_ping=True,
    pool_recycle=300,
    # SSL configuration for Neon
    connect_args={
        "ssl": "require" if "neon.tech" in DATABASE_URL else False
    }
)

# Create async session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

def import_models():
    """Import all models to ensure they are registered with SQLAlchemy"""
    from src.models import User, Message, Feedback, Post, Like, Bookmark, UrlBookmark
    return User, Message, Feedback, Post, Like, Bookmark, UrlBookmark

@asynccontextmanager
async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """Get database session with automatic cleanup"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

async def init_db():
    """Initialize database tables"""
    try:
        # Import models to register them
        import_models()
        
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("Database tables created successfully")
    except Exception as e:
        logger.error(f"Error creating database tables: {e}")
        raise

async def close_db():
    """Close database connections"""
    await engine.dispose()
    logger.info("Database connections closed")

async def test_connection():
    """Test database connection"""
    try:
        async with engine.begin() as conn:
            await conn.execute(text("SELECT 1"))
        logger.info("Database connection test successful")
        return True
    except Exception as e:
        logger.error(f"Database connection test failed: {e}")
        return False 