"""
S3 Manager for handling S3 operations in the backend application.
"""

import os
import boto3
from botocore.exceptions import ClientError, NoCredentialsError
from typing import Optional, List, Dict, Any, BinaryIO
import logging
from datetime import datetime

from .logging_manager import LoggingManager

logger = LoggingManager.get_logger("s3_manager")


class S3Manager:
    """Manager class for S3 operations."""
    
    def __init__(self, bucket_name: Optional[str] = None, region: Optional[str] = None):
        """
        Initialize S3 manager.
        
        Args:
            bucket_name: S3 bucket name (defaults to environment variable)
            region: AWS region (defaults to environment variable)
        """
        self.bucket_name = bucket_name or os.getenv("S3_APP_BUCKET")
        self.region = region or os.getenv("S3_REGION", "us-east-1")
        
        if not self.bucket_name:
            raise ValueError("S3 bucket name must be provided or set in S3_APP_BUCKET environment variable")
        
        # Initialize S3 client
        try:
            self.s3_client = boto3.client('s3', region_name=self.region)
            logger.info(f"S3 client initialized for bucket: {self.bucket_name}")
        except Exception as e:
            logger.error(f"Failed to initialize S3 client: {e}")
            raise
    
    def upload_file(self, file_path: str, s3_key: str, content_type: Optional[str] = None) -> bool:
        """
        Upload a file to S3.
        
        Args:
            file_path: Local file path
            s3_key: S3 object key
            content_type: Content type of the file
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            extra_args = {}
            if content_type:
                extra_args['ContentType'] = content_type
            
            self.s3_client.upload_file(file_path, self.bucket_name, s3_key, ExtraArgs=extra_args)
            logger.info(f"File uploaded successfully: {file_path} -> s3://{self.bucket_name}/{s3_key}")
            return True
        except (ClientError, NoCredentialsError) as e:
            logger.error(f"Failed to upload file {file_path}: {e}")
            return False
    
    def upload_fileobj(self, file_obj: BinaryIO, s3_key: str, content_type: Optional[str] = None) -> bool:
        """
        Upload a file object to S3.
        
        Args:
            file_obj: File-like object
            s3_key: S3 object key
            content_type: Content type of the file
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            extra_args = {}
            if content_type:
                extra_args['ContentType'] = content_type
            
            self.s3_client.upload_fileobj(file_obj, self.bucket_name, s3_key, ExtraArgs=extra_args)
            logger.info(f"File object uploaded successfully: s3://{self.bucket_name}/{s3_key}")
            return True
        except (ClientError, NoCredentialsError) as e:
            logger.error(f"Failed to upload file object: {e}")
            return False
    
    def download_file(self, s3_key: str, local_path: str) -> bool:
        """
        Download a file from S3.
        
        Args:
            s3_key: S3 object key
            local_path: Local file path
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            self.s3_client.download_file(self.bucket_name, s3_key, local_path)
            logger.info(f"File downloaded successfully: s3://{self.bucket_name}/{s3_key} -> {local_path}")
            return True
        except (ClientError, NoCredentialsError) as e:
            logger.error(f"Failed to download file {s3_key}: {e}")
            return False
    
    def get_object(self, s3_key: str) -> Optional[Dict[str, Any]]:
        """
        Get an object from S3.
        
        Args:
            s3_key: S3 object key
            
        Returns:
            Dict containing object data or None if failed
        """
        try:
            response = self.s3_client.get_object(Bucket=self.bucket_name, Key=s3_key)
            logger.info(f"Object retrieved successfully: s3://{self.bucket_name}/{s3_key}")
            return response
        except (ClientError, NoCredentialsError) as e:
            logger.error(f"Failed to get object {s3_key}: {e}")
            return None
    
    def delete_object(self, s3_key: str) -> bool:
        """
        Delete an object from S3.
        
        Args:
            s3_key: S3 object key
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            self.s3_client.delete_object(Bucket=self.bucket_name, Key=s3_key)
            logger.info(f"Object deleted successfully: s3://{self.bucket_name}/{s3_key}")
            return True
        except (ClientError, NoCredentialsError) as e:
            logger.error(f"Failed to delete object {s3_key}: {e}")
            return False
    
    def list_objects(self, prefix: str = "", max_keys: int = 1000) -> List[Dict[str, Any]]:
        """
        List objects in S3 bucket with given prefix.
        
        Args:
            prefix: Object key prefix
            max_keys: Maximum number of keys to return
            
        Returns:
            List of object dictionaries
        """
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=prefix,
                MaxKeys=max_keys
            )
            
            objects = response.get('Contents', [])
            logger.info(f"Listed {len(objects)} objects with prefix '{prefix}'")
            return objects
        except (ClientError, NoCredentialsError) as e:
            logger.error(f"Failed to list objects with prefix '{prefix}': {e}")
            return []
    
    def object_exists(self, s3_key: str) -> bool:
        """
        Check if an object exists in S3.
        
        Args:
            s3_key: S3 object key
            
        Returns:
            bool: True if object exists, False otherwise
        """
        try:
            self.s3_client.head_object(Bucket=self.bucket_name, Key=s3_key)
            return True
        except ClientError as e:
            if e.response['Error']['Code'] == '404':
                return False
            logger.error(f"Error checking object existence {s3_key}: {e}")
            return False
    
    def get_object_url(self, s3_key: str, expires_in: int = 3600) -> Optional[str]:
        """
        Generate a presigned URL for an S3 object.
        
        Args:
            s3_key: S3 object key
            expires_in: URL expiration time in seconds
            
        Returns:
            str: Presigned URL or None if failed
        """
        try:
            url = self.s3_client.generate_presigned_url(
                'get_object',
                Params={'Bucket': self.bucket_name, 'Key': s3_key},
                ExpiresIn=expires_in
            )
            logger.info(f"Generated presigned URL for s3://{self.bucket_name}/{s3_key}")
            return url
        except (ClientError, NoCredentialsError) as e:
            logger.error(f"Failed to generate presigned URL for {s3_key}: {e}")
            return None
    
    def copy_object(self, source_key: str, dest_key: str) -> bool:
        """
        Copy an object within the same bucket.
        
        Args:
            source_key: Source S3 object key
            dest_key: Destination S3 object key
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            copy_source = {'Bucket': self.bucket_name, 'Key': source_key}
            self.s3_client.copy_object(CopySource=copy_source, Bucket=self.bucket_name, Key=dest_key)
            logger.info(f"Object copied successfully: {source_key} -> {dest_key}")
            return True
        except (ClientError, NoCredentialsError) as e:
            logger.error(f"Failed to copy object {source_key} to {dest_key}: {e}")
            return False
    
    def get_bucket_info(self) -> Dict[str, Any]:
        """
        Get bucket information.
        
        Returns:
            Dict containing bucket information
        """
        try:
            response = self.s3_client.head_bucket(Bucket=self.bucket_name)
            logger.info(f"Retrieved bucket info for {self.bucket_name}")
            return {
                'bucket_name': self.bucket_name,
                'region': self.region,
                'status': 'accessible'
            }
        except (ClientError, NoCredentialsError) as e:
            logger.error(f"Failed to get bucket info for {self.bucket_name}: {e}")
            return {
                'bucket_name': self.bucket_name,
                'region': self.region,
                'status': 'inaccessible',
                'error': str(e)
            }


# Convenience functions for common operations
def upload_data_file(file_path: str, data_type: str = "input") -> Optional[str]:
    """
    Upload a data file to the appropriate S3 directory.
    
    Args:
        file_path: Local file path
        data_type: Type of data (input, output, temp)
        
    Returns:
        str: S3 key of uploaded file or None if failed
    """
    try:
        s3_manager = S3Manager()
        filename = os.path.basename(file_path)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        s3_key = f"data/{data_type}/{timestamp}_{filename}"
        
        if s3_manager.upload_file(file_path, s3_key):
            return s3_key
        return None
    except Exception as e:
        logger.error(f"Failed to upload data file {file_path}: {e}")
        return None


def download_data_file(s3_key: str, local_path: str) -> bool:
    """
    Download a data file from S3.
    
    Args:
        s3_key: S3 object key
        local_path: Local file path
        
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        s3_manager = S3Manager()
        return s3_manager.download_file(s3_key, local_path)
    except Exception as e:
        logger.error(f"Failed to download data file {s3_key}: {e}")
        return False


def list_data_files(data_type: str = "input") -> List[Dict[str, Any]]:
    """
    List data files of a specific type.
    
    Args:
        data_type: Type of data (input, output, temp)
        
    Returns:
        List of file information dictionaries
    """
    try:
        s3_manager = S3Manager()
        prefix = f"data/{data_type}/"
        return s3_manager.list_objects(prefix=prefix)
    except Exception as e:
        logger.error(f"Failed to list data files for type {data_type}: {e}")
        return [] 