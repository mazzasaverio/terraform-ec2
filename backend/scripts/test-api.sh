#!/bin/bash

# Test script for the API endpoints
set -e

API_URL="${1:-http://localhost:8000}"
echo "Testing API at: $API_URL"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

# Test health endpoint
echo -e "\n${YELLOW}Testing health endpoint...${NC}"
if curl -s "$API_URL/health" | grep -q "healthy"; then
    print_status 0 "Health check passed"
else
    print_status 1 "Health check failed"
fi

# Test root endpoint
echo -e "\n${YELLOW}Testing root endpoint...${NC}"
if curl -s "$API_URL/" | grep -q "Simple Backend API"; then
    print_status 0 "Root endpoint working"
else
    print_status 1 "Root endpoint failed"
fi

# Test authentication
echo -e "\n${YELLOW}Testing authentication...${NC}"
TOKEN=$(curl -s -X POST "$API_URL/auth/login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin&password=admin123" | jq -r '.access_token' 2>/dev/null)

if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
    print_status 0 "Authentication successful"
    
    # Test protected endpoints
    echo -e "\n${YELLOW}Testing protected endpoints...${NC}"
    
    # Test get current user
    if curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/auth/me" | grep -q "admin"; then
        print_status 0 "Get current user working"
    else
        print_status 1 "Get current user failed"
    fi
    
    # Test create message
    MESSAGE_RESPONSE=$(curl -s -X POST "$API_URL/messages" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"message": "Test message from script", "user_id": "test_user"}')
    
    if echo "$MESSAGE_RESPONSE" | grep -q "Test message from script"; then
        print_status 0 "Create message working"
        MESSAGE_ID=$(echo "$MESSAGE_RESPONSE" | jq -r '.id')
        
        # Test get message
        if curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/messages/$MESSAGE_ID" | grep -q "Test message from script"; then
            print_status 0 "Get message working"
        else
            print_status 1 "Get message failed"
        fi
        
        # Test list messages
        if curl -s -H "Authorization: Bearer $TOKEN" "$API_URL/messages" | grep -q "Test message from script"; then
            print_status 0 "List messages working"
        else
            print_status 1 "List messages failed"
        fi
        
        # Test delete message
        if curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "$API_URL/messages/$MESSAGE_ID" | grep -q "deleted"; then
            print_status 0 "Delete message working"
        else
            print_status 1 "Delete message failed"
        fi
    else
        print_status 1 "Create message failed"
    fi
    
else
    print_status 1 "Authentication failed"
fi

echo -e "\n${YELLOW}API testing completed!${NC}" 