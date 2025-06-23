import pytest
from fastapi.testclient import TestClient
from src.main import app

client = TestClient(app)


def test_root():
    """Test root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Simple Backend API"
    assert data["version"] == "0.1.0"


def test_health():
    """Test health endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "timestamp" in data


def test_create_message():
    """Test creating a message"""
    message_data = {"message": "Test message", "user_id": "test_user"}
    response = client.post("/messages", json=message_data)
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Test message"
    assert data["user_id"] == "test_user"
    assert data["id"] == 1
    assert data["processed"] is True


def test_get_message():
    """Test getting a message by ID"""
    # First create a message
    message_data = {"message": "Test message for get", "user_id": "test_user"}
    create_response = client.post("/messages", json=message_data)
    message_id = create_response.json()["id"]

    # Now get it
    response = client.get(f"/messages/{message_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Test message for get"
    assert data["user_id"] == "test_user"


def test_get_nonexistent_message():
    """Test getting a message that doesn't exist"""
    response = client.get("/messages/999")
    assert response.status_code == 404


def test_list_messages():
    """Test listing all messages"""
    response = client.get("/messages")
    assert response.status_code == 200
    data = response.json()
    assert "count" in data
    assert "messages" in data
    assert isinstance(data["messages"], list)


def test_delete_message():
    """Test deleting a message"""
    # First create a message
    message_data = {"message": "Test message to delete", "user_id": "test_user"}
    create_response = client.post("/messages", json=message_data)
    message_id = create_response.json()["id"]

    # Now delete it
    response = client.delete(f"/messages/{message_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Message deleted"

    # Verify it's gone
    get_response = client.get(f"/messages/{message_id}")
    assert get_response.status_code == 404
