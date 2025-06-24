from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from pydantic import BaseModel
from typing import Dict, Any
from datetime import datetime, timedelta
import os

from .utils.logging_manager import LoggingManager
from .utils.auth import create_access_token, verify_token, authenticate_user

# Configure logging using the centralized manager
log_level = os.getenv("LOG_LEVEL", "INFO")
debug_mode = os.getenv("DEBUG", "false").lower() == "true"
LoggingManager.configure_logging(level=log_level, debug=debug_mode)

# Add app-specific log handler
LoggingManager.add_file_handler(
    "logs/app.log",
    level=log_level,
    rotation="10 MB",
    retention="30 days"
)

logger = LoggingManager.get_logger("main")

# Configure OAuth2 scheme for Swagger
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# Create FastAPI app
app = FastAPI(
    title="Simple Backend", description="A simple backend for testing", version="0.1.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class MessageRequest(BaseModel):
    message: str
    user_id: str = "anonymous"


class MessageResponse(BaseModel):
    id: int
    message: str
    user_id: str
    timestamp: datetime
    processed: bool = True


class Token(BaseModel):
    access_token: str
    token_type: str


# In-memory storage for testing
messages_store: Dict[int, Dict[str, Any]] = {}
next_id = 1


@app.get("/")
async def root():
    """Root endpoint"""
    logger.info("Root endpoint accessed")
    return {
        "message": "Simple Backend API",
        "version": "0.1.0",
        "endpoints": ["/", "/health", "/messages", "/messages/{message_id}"],
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    logger.info("Health check accessed")
    return {"status": "healthy", "timestamp": datetime.now(), "uptime": "OK"}


@app.post("/auth/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """Login endpoint to get JWT token"""
    logger.info(f"Login attempt for user: {form_data.username}")
    
    user = authenticate_user(form_data.username, form_data.password)
    if not user:
        logger.warning(f"Failed login attempt for user: {form_data.username}")
        raise HTTPException(
            status_code=401,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=30)
    access_token = create_access_token(
        data={"sub": user["username"], "role": user["role"]},
        expires_delta=access_token_expires
    )
    
    logger.info(f"User {user['username']} logged in successfully")
    return {"access_token": access_token, "token_type": "bearer"}


@app.get("/auth/me")
async def get_current_user(token_data: dict = Depends(verify_token)):
    """Get current user info from token"""
    return {"username": token_data["sub"], "role": token_data.get("role")}


@app.post("/messages", response_model=MessageResponse)
async def create_message(request: MessageRequest, token_data: dict = Depends(verify_token)):
    """Create a new message (requires authentication)"""
    global next_id

    logger.info(f"Creating message for user: {request.user_id} (authenticated as: {token_data['sub']})")

    message_data = {
        "id": next_id,
        "message": request.message,
        "user_id": request.user_id,
        "timestamp": datetime.now(),
        "processed": True,
    }

    messages_store[next_id] = message_data
    next_id += 1

    logger.info(f"Message created with ID: {message_data['id']}")

    return MessageResponse(**message_data)


@app.get("/messages/{message_id}")
async def get_message(message_id: int, token_data: dict = Depends(verify_token)):
    """Get a message by ID (requires authentication)"""
    logger.info(f"Retrieving message with ID: {message_id} (user: {token_data['sub']})")

    if message_id not in messages_store:
        logger.warning(f"Message not found: {message_id}")
        raise HTTPException(status_code=404, detail="Message not found")

    return messages_store[message_id]


@app.get("/messages")
async def list_messages(token_data: dict = Depends(verify_token)):
    """List all messages (requires authentication)"""
    logger.info(f"Listing all messages (user: {token_data['sub']})")
    return {"count": len(messages_store), "messages": list(messages_store.values())}


@app.delete("/messages/{message_id}")
async def delete_message(message_id: int, token_data: dict = Depends(verify_token)):
    """Delete a message (requires authentication)"""
    logger.info(f"Deleting message with ID: {message_id} (user: {token_data['sub']})")

    if message_id not in messages_store:
        logger.warning(f"Message not found for deletion: {message_id}")
        raise HTTPException(status_code=404, detail="Message not found")

    deleted_message = messages_store.pop(message_id)
    logger.info(f"Message deleted: {message_id}")

    return {"message": "Message deleted", "deleted": deleted_message}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
