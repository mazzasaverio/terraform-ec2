# S3 Storage Setup Guide

This guide explains how to set up and use S3 storage with your Terraform infrastructure, allowing you to connect to S3 both locally and from the EC2 instance.

## Overview

The S3 integration includes:
- **Two S3 buckets**: One for application data and one for logs
- **IAM roles and policies**: Secure access for EC2 instances
- **Local and remote access**: Connect from both your local machine and EC2
- **FastAPI integration**: S3 operations through the backend API
- **Automated scripts**: Easy setup and sync operations

## Prerequisites

1. **AWS CLI installed and configured**
2. **Terraform infrastructure deployed**
3. **SSH access to EC2 instance**

## Quick Setup

### 1. Deploy Infrastructure with S3

```bash
# Navigate to infrastructure directory
cd infrastructure

# Initialize Terraform (if not done already)
terraform init

# Apply the infrastructure (includes S3 buckets)
terraform apply
```

### 2. Run S3 Setup Script

```bash
# From project root
chmod +x scripts/setup-s3.sh
./scripts/setup-s3.sh
```

This script will:
- Test S3 access
- Create directory structure in S3
- Generate sync scripts
- Create configuration files

### 3. Source Configuration

```bash
# Source the generated configuration
source s3-config.env
```

## S3 Bucket Structure

```
s3://your-project-dev-app-data-xxxxxxxx/
├── data/
│   ├── input/          # Input files
│   ├── output/         # Processed results
│   ├── temp/           # Temporary files
│   └── logs/           # Application logs
```

```
s3://your-project-dev-logs-xxxxxxxx/
├── app.logs/           # Application logs
├── system.logs/        # System logs
└── access.logs/        # Access logs
```

## Local S3 Operations

### Using AWS CLI

```bash
# List files in app bucket
aws s3 ls s3://$(terraform output -raw app_bucket_name)/data/

# Upload a file
aws s3 cp local-file.txt s3://$(terraform output -raw app_bucket_name)/data/input/

# Download a file
aws s3 cp s3://$(terraform output -raw app_bucket_name)/data/output/result.txt ./

# Sync entire directories
aws s3 sync data/ s3://$(terraform output -raw app_bucket_name)/data/
```

### Using Sync Script

```bash
# Sync local data to S3
./sync-s3.sh up

# Sync S3 data to local
./sync-s3.sh down

# Sync logs to S3
./sync-s3.sh logs
```

## EC2 S3 Operations

### Connect to EC2

```bash
# SSH to your EC2 instance
ssh -i .ssh/terraform-ec2-key ubuntu@$(terraform output -raw instance_public_ip)
```

### Test S3 Access

```bash
# Test S3 connectivity
s3-test

# This will test both app and logs buckets
```

### S3 Operations on EC2

```bash
# Sync data to S3
s3-sync up

# Sync data from S3
s3-sync down

# Sync logs to S3
s3-sync logs

# List S3 files
aws s3 ls s3://$(source s3-config.env && echo $S3_APP_BUCKET)/data/
```

## FastAPI S3 Integration

The backend includes S3 endpoints for programmatic access:

### Authentication Required

All S3 endpoints require JWT authentication. First, get a token:

```bash
curl -X POST "http://your-ec2-ip:8000/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

### Available Endpoints

#### List Files
```bash
curl -X GET "http://your-ec2-ip:8000/s3/files?data_type=input" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

#### Upload File
```bash
curl -X POST "http://your-ec2-ip:8000/s3/upload" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@local-file.txt" \
  -F "data_type=input"
```

#### Get File Info
```bash
curl -X GET "http://your-ec2-ip:8000/s3/download/data/input/file.txt" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

#### Delete File
```bash
curl -X DELETE "http://your-ec2-ip:8000/s3/files/data/input/file.txt" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

#### S3 Health Check
```bash
curl -X GET "http://your-ec2-ip:8000/s3/health" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Python S3 Operations

### Using S3Manager Class

```python
from src.utils.s3_manager import S3Manager

# Initialize S3 manager
s3_manager = S3Manager()

# Upload a file
s3_manager.upload_file("local-file.txt", "data/input/file.txt")

# Download a file
s3_manager.download_file("data/input/file.txt", "downloaded-file.txt")

# List files
files = s3_manager.list_objects(prefix="data/input/")

# Get presigned URL
url = s3_manager.get_object_url("data/input/file.txt")

# Delete file
s3_manager.delete_object("data/input/file.txt")
```

### Using Convenience Functions

```python
from src.utils.s3_manager import upload_data_file, list_data_files

# Upload to specific data type directory
s3_key = upload_data_file("my-file.txt", "input")

# List files by type
input_files = list_data_files("input")
output_files = list_data_files("output")
```

## Security Features

### IAM Policies

The EC2 instance has the following S3 permissions:
- `s3:GetObject` - Read files
- `s3:PutObject` - Upload files
- `s3:DeleteObject` - Delete files
- `s3:ListBucket` - List bucket contents

### Bucket Security

- **Server-side encryption**: AES256 encryption enabled
- **Versioning**: Enabled for data recovery
- **Public access**: Blocked for security
- **Lifecycle policies**: Automatic cleanup of old versions and logs

## Monitoring and Logging

### S3 Access Logs

S3 access is logged through:
- CloudTrail (if enabled)
- Application logs via Logfire
- S3 server access logs (configurable)

### Health Monitoring

```bash
# Check S3 connectivity from EC2
s3-test

# Check S3 health via API
curl -X GET "http://your-ec2-ip:8000/s3/health" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Troubleshooting

### Common Issues

1. **Access Denied**
   - Check IAM role permissions
   - Verify bucket names in configuration
   - Ensure AWS credentials are configured

2. **Bucket Not Found**
   - Verify Terraform deployment completed
   - Check bucket names in outputs
   - Ensure correct AWS region

3. **Upload Failures**
   - Check file permissions
   - Verify disk space
   - Check network connectivity

### Debug Commands

```bash
# Check AWS configuration
aws sts get-caller-identity

# Test S3 access
aws s3 ls s3://$(terraform output -raw app_bucket_name)/

# Check IAM role
aws iam get-role --role-name $(terraform output -raw ec2_instance_profile_name)

# View CloudTrail logs (if enabled)
aws logs describe-log-groups --log-group-name-prefix CloudTrail
```

## Best Practices

1. **Use appropriate data types**: Store files in the correct directory (input/output/temp)
2. **Clean up temporary files**: Remove temp files after processing
3. **Monitor costs**: S3 charges based on storage and requests
4. **Backup important data**: Use versioning for critical files
5. **Use presigned URLs**: For secure, time-limited access to files

## Cost Optimization

- **Lifecycle policies**: Automatically move old data to cheaper storage classes
- **Compression**: Compress files before upload for storage savings
- **Batch operations**: Use batch operations for multiple files
- **Monitoring**: Set up CloudWatch alarms for cost monitoring

## Next Steps

1. **Set up automated backups**: Configure regular S3 backups
2. **Implement data processing**: Use S3 as input/output for data pipelines
3. **Add monitoring**: Set up CloudWatch dashboards for S3 metrics
4. **Optimize performance**: Use S3 Transfer Acceleration if needed
5. **Implement caching**: Use CloudFront for frequently accessed files 