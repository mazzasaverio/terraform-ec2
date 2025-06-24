import pytest
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from src.utils.database import get_db_session, init_db, close_db
from src.repositories.message_repository import MessageRepository
from src.repositories.user_repository import UserRepository
from src.models.message import Message
from src.models.user import User


@pytest.fixture
async def db_session():
    """Provide database session for tests"""
    async with get_db_session() as session:
        yield session


@pytest.fixture
async def message_repo(db_session):
    """Provide message repository for tests"""
    return MessageRepository(db_session)


@pytest.fixture
async def user_repo(db_session):
    """Provide user repository for tests"""
    return UserRepository(db_session)


@pytest.mark.asyncio
async def test_create_message(message_repo):
    """Test creating a message"""
    message = await message_repo.create(
        message="Test message",
        user_id="test_user",
        processed=True
    )
    
    assert message.id is not None
    assert message.message == "Test message"
    assert message.user_id == "test_user"
    assert message.processed is True


@pytest.mark.asyncio
async def test_get_message_by_id(message_repo):
    """Test getting a message by ID"""
    # Create a message first
    created_message = await message_repo.create(
        message="Test message for retrieval",
        user_id="test_user"
    )
    
    # Retrieve the message
    retrieved_message = await message_repo.get_by_id(created_message.id)
    
    assert retrieved_message is not None
    assert retrieved_message.id == created_message.id
    assert retrieved_message.message == "Test message for retrieval"


@pytest.mark.asyncio
async def test_get_all_messages(message_repo):
    """Test getting all messages"""
    # Create multiple messages
    await message_repo.create("Message 1", "user1")
    await message_repo.create("Message 2", "user2")
    await message_repo.create("Message 3", "user1")
    
    # Get all messages
    messages = await message_repo.get_all()
    
    assert len(messages) >= 3
    # Messages should be ordered by timestamp desc
    assert messages[0].timestamp >= messages[1].timestamp


@pytest.mark.asyncio
async def test_get_messages_by_user_id(message_repo):
    """Test getting messages by user ID"""
    # Create messages for different users
    await message_repo.create("User 1 message", "user1")
    await message_repo.create("User 2 message", "user2")
    await message_repo.create("Another user 1 message", "user1")
    
    # Get messages for user1
    user1_messages = await message_repo.get_by_user_id("user1")
    
    assert len(user1_messages) >= 2
    for message in user1_messages:
        assert message.user_id == "user1"


@pytest.mark.asyncio
async def test_delete_message(message_repo):
    """Test deleting a message"""
    # Create a message
    message = await message_repo.create("Message to delete", "test_user")
    message_id = message.id
    
    # Delete the message
    success = await message_repo.delete(message_id)
    assert success is True
    
    # Verify message is deleted
    deleted_message = await message_repo.get_by_id(message_id)
    assert deleted_message is None


@pytest.mark.asyncio
async def test_create_user(user_repo):
    """Test creating a user"""
    user = await user_repo.create(
        username="testuser",
        password="testpass123",
        email="test@example.com",
        role="user"
    )
    
    assert user.id is not None
    assert user.username == "testuser"
    assert user.email == "test@example.com"
    assert user.role == "user"
    assert user.is_active is True


@pytest.mark.asyncio
async def test_authenticate_user(user_repo):
    """Test user authentication"""
    # Create a user
    await user_repo.create(
        username="authuser",
        password="authpass123",
        email="auth@example.com"
    )
    
    # Test successful authentication
    authenticated_user = await user_repo.authenticate("authuser", "authpass123")
    assert authenticated_user is not None
    assert authenticated_user.username == "authuser"
    
    # Test failed authentication
    failed_auth = await user_repo.authenticate("authuser", "wrongpassword")
    assert failed_auth is None


@pytest.mark.asyncio
async def test_get_user_by_username(user_repo):
    """Test getting user by username"""
    # Create a user
    created_user = await user_repo.create(
        username="getuser",
        password="getpass123",
        email="get@example.com"
    )
    
    # Get user by username
    retrieved_user = await user_repo.get_by_username("getuser")
    
    assert retrieved_user is not None
    assert retrieved_user.id == created_user.id
    assert retrieved_user.username == "getuser"


@pytest.mark.asyncio
async def test_password_hashing(user_repo):
    """Test password hashing and verification"""
    password = "testpassword123"
    
    # Hash password
    hashed = user_repo.get_password_hash(password)
    assert hashed != password
    assert len(hashed) > len(password)
    
    # Verify password
    assert user_repo.verify_password(password, hashed) is True
    assert user_repo.verify_password("wrongpassword", hashed) is False 