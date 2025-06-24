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
        "endpoints": ["/", "/health", "/messages", "/messages/{message_id}", "/s3/files", "/s3/upload"],
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
        logger.error(f"Failed to list S3 files: {e}")
        raise HTTPException(status_code=500, detail="Failed to list S3 files")


@app.post("/s3/upload", response_model=S3UploadResponse)
async def upload_file_to_s3(
    file: UploadFile = File(...),
    data_type: str = "input",
    token_data: dict = Depends(verify_token)
):
    """Upload a file to S3 (requires authentication)"""
    logger.info(f"Uploading file to S3: {file.filename} (user: {token_data['sub']})")
    
    try:
        # Save uploaded file temporarily
        temp_path = f"/tmp/{file.filename}"
        with open(temp_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
        
        # Upload to S3
        s3_key = upload_data_file(temp_path, data_type)
        
        # Clean up temp file
        os.remove(temp_path)
        
        if s3_key:
            logger.info(f"File uploaded successfully: {s3_key}")
            return S3UploadResponse(
                success=True,
                s3_key=s3_key,
                message="File uploaded successfully"
            )
        else:
            raise HTTPException(status_code=500, detail="Failed to upload file to S3")
            
    except Exception as e:
        logger.error(f"Failed to upload file: {e}")
        raise HTTPException(status_code=500, detail="Failed to upload file")


@app.get("/s3/download/{s3_key:path}")
async def download_file_from_s3(s3_key: str, token_data: dict = Depends(verify_token)):
    """Download a file from S3 (requires authentication)"""
    logger.info(f"Downloading file from S3: {s3_key} (user: {token_data['sub']})")
    
    try:
        s3_manager = S3Manager()
        object_data = s3_manager.get_object(s3_key)
        
        if not object_data:
            raise HTTPException(status_code=404, detail="File not found in S3")
        
        return {
            "s3_key": s3_key,
            "size": object_data["ContentLength"],
            "content_type": object_data.get("ContentType", "application/octet-stream"),
            "last_modified": object_data["LastModified"],
            "download_url": s3_manager.get_object_url(s3_key)
        }
        
    except Exception as e:
        logger.error(f"Failed to get file info: {e}")
        raise HTTPException(status_code=500, detail="Failed to get file info")


@app.delete("/s3/files/{s3_key:path}")
async def delete_file_from_s3(s3_key: str, token_data: dict = Depends(verify_token)):
    """Delete a file from S3 (requires authentication)"""
    logger.info(f"Deleting file from S3: {s3_key} (user: {token_data['sub']})")
    
    try:
        s3_manager = S3Manager()
        if s3_manager.delete_object(s3_key):
            return {"message": "File deleted successfully", "s3_key": s3_key}
        else:
            raise HTTPException(status_code=500, detail="Failed to delete file from S3")
            
    except Exception as e:
        logger.error(f"Failed to delete file: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete file")


@app.get("/s3/health")
async def s3_health_check(token_data: dict = Depends(verify_token)):
    """Check S3 connectivity (requires authentication)"""
    logger.info(f"S3 health check (user: {token_data['sub']})")
    
    try:
        s3_manager = S3Manager()
        bucket_info = s3_manager.get_bucket_info()
        return {
            "s3_status": bucket_info["status"],
            "bucket_name": bucket_info["bucket_name"],
            "region": bucket_info["region"],
            "timestamp": datetime.now()
        }
    except Exception as e:
        logger.error(f"S3 health check failed: {e}")
        return {
            "s3_status": "error",
            "error": str(e),
            "timestamp": datetime.now()
        }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
