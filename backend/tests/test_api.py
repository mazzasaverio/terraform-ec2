import pytest
from fastapi.testclient import TestClient
from src.main import app
from src.utils.logging_manager import LoggingManager

# Configure logging for tests
LoggingManager.configure_logging(level="INFO", debug=False)
logger = LoggingManager.get_logger("tests")

client = TestClient(app)

# Test user credentials
TEST_USER = {"username": "admin", "password": "admin123"}


def get_auth_token():
    """Helper function to get authentication token"""
    response = client.post("/auth/login", data=TEST_USER)
    assert response.status_code == 200
    return response.json()["access_token"]


def test_root():
    """Test root endpoint (no auth required)"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Simple Backend API"
    assert data["version"] == "0.1.0"


def test_health():
    """Test health endpoint (no auth required)"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "timestamp" in data


def test_login():
    """Test login endpoint"""
    response = client.post("/auth/login", data=TEST_USER)
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_login_invalid():
    """Test login with invalid credentials"""
    response = client.post("/auth/login", data={"username": "invalid", "password": "invalid"})
    assert response.status_code == 401


def test_get_current_user():
    """Test getting current user info"""
    token = get_auth_token()
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get("/auth/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["username"] == "admin"
    assert data["role"] == "admin"


def test_create_message():
    """Test creating a message with authentication"""
    token = get_auth_token()
    headers = {"Authorization": f"Bearer {token}"}
    message_data = {"message": "Test message", "user_id": "test_user"}
    response = client.post("/messages", json=message_data, headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Test message"
    assert data["user_id"] == "test_user"
    assert data["processed"] is True


def test_create_message_no_auth():
    """Test creating a message without authentication"""
    message_data = {"message": "Test message", "user_id": "test_user"}
    response = client.post("/messages", json=message_data)
    assert response.status_code == 403


def test_get_message():
    """Test getting a message by ID with authentication"""
    token = get_auth_token()
    headers = {"Authorization": f"Bearer {token}"}
    
    # First create a message
    message_data = {"message": "Test message for get", "user_id": "test_user"}
    create_response = client.post("/messages", json=message_data, headers=headers)
    message_id = create_response.json()["id"]

    # Now get it
    response = client.get(f"/messages/{message_id}", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Test message for get"
    assert data["user_id"] == "test_user"


def test_get_nonexistent_message():
    """Test getting a message that doesn't exist"""
    token = get_auth_token()
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get("/messages/999", headers=headers)
    assert response.status_code == 404


def test_list_messages():
    """Test listing all messages with authentication"""
    token = get_auth_token()
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get("/messages", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "count" in data
    assert "messages" in data
    assert isinstance(data["messages"], list)


def test_delete_message():
    """Test deleting a message with authentication"""
    token = get_auth_token()
    headers = {"Authorization": f"Bearer {token}"}
    
    # First create a message
    message_data = {"message": "Test message to delete", "user_id": "test_user"}
    create_response = client.post("/messages", json=message_data, headers=headers)
    message_id = create_response.json()["id"]

    # Now delete it
    response = client.delete(f"/messages/{message_id}", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Message deleted"

    # Verify it's gone
    get_response = client.get(f"/messages/{message_id}", headers=headers)
    assert get_response.status_code == 404
