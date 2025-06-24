from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, Any
from datetime import datetime
import os

from .utils.logging_manager import LoggingManager

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

# Create FastAPI app
app = FastAPI(
    title="Simple Backend", description="A simple backend for testing", version="0.1.0"
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


@app.post("/messages", response_model=MessageResponse)
async def create_message(request: MessageRequest):
    """Create a new message"""
    global next_id

    logger.info(f"Creating message for user: {request.user_id}")

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
async def get_message(message_id: int):
    """Get a message by ID"""
    logger.info(f"Retrieving message with ID: {message_id}")

    if message_id not in messages_store:
        logger.warning(f"Message not found: {message_id}")
        raise HTTPException(status_code=404, detail="Message not found")

    return messages_store[message_id]


@app.get("/messages")
async def list_messages():
    """List all messages"""
    logger.info("Listing all messages")
    return {"count": len(messages_store), "messages": list(messages_store.values())}


@app.delete("/messages/{message_id}")
async def delete_message(message_id: int):
    """Delete a message"""
    logger.info(f"Deleting message with ID: {message_id}")

    if message_id not in messages_store:
        logger.warning(f"Message not found for deletion: {message_id}")
        raise HTTPException(status_code=404, detail="Message not found")

    deleted_message = messages_store.pop(message_id)
    logger.info(f"Message deleted: {message_id}")

    return {"message": "Message deleted", "deleted": deleted_message}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
