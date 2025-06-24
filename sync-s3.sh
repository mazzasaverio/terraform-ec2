#!/bin/bash

# =============================================================================
# S3 SYNC SCRIPT
# =============================================================================

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Get bucket names from Terraform
cd infrastructure
APP_BUCKET_NAME=$(terraform output -raw app_bucket_name 2>/dev/null || echo "")
LOGS_BUCKET_NAME=$(terraform output -raw logs_bucket_name 2>/dev/null || echo "")
cd ..

if [ -z "$APP_BUCKET_NAME" ] || [ -z "$LOGS_BUCKET_NAME" ]; then
    echo "Error: Could not get bucket names from Terraform outputs"
    exit 1
fi

# Function to sync data directory to S3
sync_data_to_s3() {
    local direction=$1
    
    if [ "$direction" = "up" ]; then
        print_status "Syncing local data to S3..."
        aws s3 sync data/ s3://$APP_BUCKET_NAME/data/ --exclude "*.tmp" --exclude "*.temp"
        print_success "Data synced to S3"
    elif [ "$direction" = "down" ]; then
        print_status "Syncing S3 data to local..."
        aws s3 sync s3://$APP_BUCKET_NAME/data/ data/ --exclude "*.tmp" --exclude "*.temp"
        print_success "Data synced from S3"
    else
        echo "Usage: $0 {up|down}"
        echo "  up   - Sync local data to S3"
        echo "  down - Sync S3 data to local"
        exit 1
    fi
}

# Function to sync logs to S3
sync_logs_to_s3() {
    print_status "Syncing logs to S3..."
    aws s3 sync logs/ s3://$LOGS_BUCKET_NAME/ --exclude "*.tmp" --exclude "*.temp"
    print_success "Logs synced to S3"
}

# Main execution
case "${1:-}" in
    "up")
        sync_data_to_s3 "up"
        ;;
    "down")
        sync_data_to_s3 "down"
        ;;
    "logs")
        sync_logs_to_s3
        ;;
    *)
        echo "Usage: $0 {up|down|logs}"
        echo "  up   - Sync local data to S3"
        echo "  down - Sync S3 data to local"
        echo "  logs - Sync logs to S3"
        exit 1
        ;;
esac
