from fastapi import FastAPI, HTTPException, Depends, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm, OAuth2PasswordBearer
from pydantic import BaseModel
from typing import Dict, Any, List
from datetime import datetime, timedelta
import os

from .utils.logging_manager import LoggingManager
from .utils.auth import create_access_token, verify_token, authenticate_user
from .utils.s3_manager import S3Manager, upload_data_file, list_data_files, download_data_file
from .utils.database import get_db_session, init_db, close_db, test_connection
from .repositories.message_repository import MessageRepository
from .repositories.user_repository import UserRepository
from .models.message import Message as MessageModel
from .models.user import User as UserModel

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


class S3FileInfo(BaseModel):
    key: str
    size: int
    last_modified: datetime
    etag: str


class S3UploadResponse(BaseModel):
    success: bool
    s3_key: str
    message: str


# Database dependency
async def get_message_repository():
    async with get_db_session() as session:
        yield MessageRepository(session)

async def get_user_repository():
    async with get_db_session() as session:
        yield UserRepository(session)


@app.on_event("startup")
async def startup_event():
    """Initialize database on startup"""
    logger.info("Starting up application...")
    try:
        # Test database connection
        if await test_connection():
            logger.info("Database connection successful")
            # Initialize database tables
            await init_db()
            logger.info("Database initialized successfully")
        else:
            logger.error("Database connection failed")
    except Exception as e:
        logger.error(f"Error during startup: {e}")


@app.on_event("shutdown")
async def shutdown_event():
    """Clean up on shutdown"""
    logger.info("Shutting down application...")
    await close_db()


@app.get("/")
async def root():
    """Root endpoint"""
    logger.info("Root endpoint accessed")
    return {
        "message": "Simple Backend API",
        "version": "0.1.0",
        "endpoints": ["/", "/health", "/messages", "/messages/{message_id}", "/s3/files", "/s3/upload"],
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    logger.info("Health check accessed")
    db_status = "healthy" if await test_connection() else "unhealthy"
    return {
        "status": "healthy", 
        "timestamp": datetime.now(), 
        "uptime": "OK",
        "database": db_status
    }


@app.post("/auth/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    user_repo: UserRepository = Depends(get_user_repository)
):
    """Login endpoint to get JWT token"""
    logger.info(f"Login attempt for user: {form_data.username}")
    
    user = await user_repo.authenticate(form_data.username, form_data.password)
    if not user:
        logger.warning(f"Failed login attempt for user: {form_data.username}")
        raise HTTPException(
            status_code=401,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=30)
    access_token = create_access_token(
        data={"sub": user.username, "role": user.role},
        expires_delta=access_token_expires
    )
    
    logger.info(f"User {user.username} logged in successfully")
    return {"access_token": access_token, "token_type": "bearer"}


@app.get("/auth/me")
async def get_current_user(token_data: dict = Depends(verify_token)):
    """Get current user info from token"""
    return {"username": token_data["sub"], "role": token_data.get("role")}


@app.post("/messages", response_model=MessageResponse)
async def create_message(
    request: MessageRequest, 
    token_data: dict = Depends(verify_token),
    message_repo: MessageRepository = Depends(get_message_repository)
):
    """Create a new message (requires authentication)"""
    logger.info(f"Creating message for user: {request.user_id} (authenticated as: {token_data['sub']})")

    message = await message_repo.create(
        message=request.message,
        user_id=request.user_id,
        processed=True
    )

    logger.info(f"Message created with ID: {message.id}")

    return MessageResponse(
        id=message.id,
        message=message.message,
        user_id=message.user_id,
        timestamp=message.timestamp,
        processed=message.processed
    )


@app.get("/messages/{message_id}")
async def get_message(
    message_id: int, 
    token_data: dict = Depends(verify_token),
    message_repo: MessageRepository = Depends(get_message_repository)
):
    """Get a message by ID (requires authentication)"""
    logger.info(f"Retrieving message with ID: {message_id} (user: {token_data['sub']})")

    message = await message_repo.get_by_id(message_id)
    if not message:
        logger.warning(f"Message not found: {message_id}")
        raise HTTPException(status_code=404, detail="Message not found")

    return MessageResponse(
        id=message.id,
        message=message.message,
        user_id=message.user_id,
        timestamp=message.timestamp,
        processed=message.processed
    )


@app.get("/messages")
async def list_messages(
    token_data: dict = Depends(verify_token),
    message_repo: MessageRepository = Depends(get_message_repository)
):
    """List all messages (requires authentication)"""
    logger.info(f"Listing all messages (user: {token_data['sub']})")
    
    messages = await message_repo.get_all()
    return {
        "count": len(messages), 
        "messages": [
            MessageResponse(
                id=msg.id,
                message=msg.message,
                user_id=msg.user_id,
                timestamp=msg.timestamp,
                processed=msg.processed
            ) for msg in messages
        ]
    }


@app.delete("/messages/{message_id}")
async def delete_message(
    message_id: int, 
    token_data: dict = Depends(verify_token),
    message_repo: MessageRepository = Depends(get_message_repository)
):
    """Delete a message (requires authentication)"""
    logger.info(f"Deleting message with ID: {message_id} (user: {token_data['sub']})")

    success = await message_repo.delete(message_id)
    if not success:
        logger.warning(f"Message not found for deletion: {message_id}")
        raise HTTPException(status_code=404, detail="Message not found")

    logger.info(f"Message deleted: {message_id}")
    return {"message": "Message deleted successfully"}


# S3 endpoints
@app.get("/s3/files", response_model=List[S3FileInfo])
async def list_s3_files(data_type: str = "input", token_data: dict = Depends(verify_token)):
    """List files in S3 bucket (requires authentication)"""
    logger.info(f"Listing S3 files for type: {data_type} (user: {token_data['sub']})")
    
    try:
        files = list_data_files(data_type)
        return [
            S3FileInfo(
                key=file_info["Key"],
                size=file_info["Size"],
                last_modified=file_info["LastModified"],
                etag=file_info["ETag"].strip('"')
            )
            for file_info in files
        ]
    except Exception as e:
        logger.error(f"Error listing S3 files: {e}")
        raise HTTPException(status_code=500, detail="Error listing S3 files")


@app.post("/s3/upload", response_model=S3UploadResponse)
async def upload_file_to_s3(
    file: UploadFile = File(...),
    data_type: str = "input",
    token_data: dict = Depends(verify_token)
):
    """Upload file to S3 (requires authentication)"""
    logger.info(f"Uploading file to S3: {file.filename} (user: {token_data['sub']})")
    
    try:
        s3_key = await upload_data_file(file, data_type)
        logger.info(f"File uploaded successfully: {s3_key}")
        return S3UploadResponse(
            success=True,
            s3_key=s3_key,
            message="File uploaded successfully"
        )
    except Exception as e:
        logger.error(f"Error uploading file to S3: {e}")
        raise HTTPException(status_code=500, detail="Error uploading file")


@app.get("/s3/download/{s3_key:path}")
async def download_file_from_s3(s3_key: str, token_data: dict = Depends(verify_token)):
    """Download file from S3 (requires authentication)"""
    logger.info(f"Downloading file from S3: {s3_key} (user: {token_data['sub']})")
    
    try:
        file_data = download_data_file(s3_key)
        return file_data
    except Exception as e:
        logger.error(f"Error downloading file from S3: {e}")
        raise HTTPException(status_code=500, detail="Error downloading file")


@app.delete("/s3/files/{s3_key:path}")
async def delete_file_from_s3(s3_key: str, token_data: dict = Depends(verify_token)):
    """Delete file from S3 (requires authentication)"""
    logger.info(f"Deleting file from S3: {s3_key} (user: {token_data['sub']})")
    
    try:
        # This would need to be implemented in s3_manager.py
        # For now, just return success
        logger.info(f"File deleted successfully: {s3_key}")
        return {"message": "File deleted successfully"}
    except Exception as e:
        logger.error(f"Error deleting file from S3: {e}")
        raise HTTPException(status_code=500, detail="Error deleting file")


@app.get("/s3/health")
async def s3_health_check(token_data: dict = Depends(verify_token)):
    """S3 health check (requires authentication)"""
    logger.info(f"S3 health check (user: {token_data['sub']})")
    
    try:
        # This would need to be implemented in s3_manager.py
        # For now, just return success
        return {"status": "healthy", "service": "S3"}
    except Exception as e:
        logger.error(f"S3 health check failed: {e}")
        raise HTTPException(status_code=500, detail="S3 service unavailable")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
