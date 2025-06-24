#!/usr/bin/env python3
"""
Example script to test the authenticated API
Demonstrates login and API usage with JWT tokens
"""

import requests
import json

# API base URL (change to your deployed URL)
BASE_URL = "http://localhost:8000"

def login(username: str, password: str) -> str:
    """Login and get JWT token"""
    response = requests.post(
        f"{BASE_URL}/auth/login",
        data={"username": username, "password": password}
    )
    
    if response.status_code == 200:
        token = response.json()["access_token"]
        print(f"✅ Login successful for {username}")
        return token
    else:
        print(f"❌ Login failed: {response.text}")
        return None

def test_api_with_auth(token: str):
    """Test API endpoints with authentication"""
    headers = {"Authorization": f"Bearer {token}"}
    
    # Test current user
    response = requests.get(f"{BASE_URL}/auth/me", headers=headers)
    if response.status_code == 200:
        user_info = response.json()
        print(f"✅ Current user: {user_info['username']} ({user_info['role']})")
    
    # Create a message
    message_data = {
        "message": "Hello from authenticated API!",
        "user_id": "api_test_user"
    }
    
    response = requests.post(
        f"{BASE_URL}/messages",
        json=message_data,
        headers=headers
    )
    
    if response.status_code == 200:
        message = response.json()
        print(f"✅ Message created with ID: {message['id']}")
        
        # Get the message back
        response = requests.get(f"{BASE_URL}/messages/{message['id']}", headers=headers)
        if response.status_code == 200:
            print(f"✅ Retrieved message: {response.json()['message']}")
        
        # List all messages
        response = requests.get(f"{BASE_URL}/messages", headers=headers)
        if response.status_code == 200:
            messages = response.json()
            print(f"✅ Total messages: {messages['count']}")
    
def test_without_auth():
    """Test API without authentication (should fail)"""
    print("\n🔒 Testing without authentication:")
    
    response = requests.post(
        f"{BASE_URL}/messages",
        json={"message": "This should fail", "user_id": "unauthorized"}
    )
    
    if response.status_code == 403:
        print("✅ Correctly blocked unauthorized request")
    else:
        print(f"❌ Unexpected response: {response.status_code}")

def main():
    """Main test function"""
    print("🚀 Testing authenticated API")
    print("=" * 40)
    
    # Test login
    token = login("admin", "admin123")
    if not token:
        print("❌ Cannot proceed without token")
        return
    
    # Test API with authentication
    print("\n🔑 Testing with authentication:")
    test_api_with_auth(token)
    
    # Test without authentication
    test_without_auth()
    
    print("\n✅ All tests completed!")

if __name__ == "__main__":
    main() 