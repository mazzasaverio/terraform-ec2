#!/bin/bash

# =============================================================================
# S3 SETUP SCRIPT
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check AWS CLI configuration
check_aws_config() {
    if ! command_exists aws; then
        print_error "AWS CLI is not installed. Please install it first."
        print_status "Installation guide: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi

    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi

    print_success "AWS CLI is configured and working"
}

# Function to get Terraform outputs
get_terraform_outputs() {
    if [ ! -d "infrastructure" ]; then
        print_error "Infrastructure directory not found. Please run this script from the project root."
        exit 1
    fi

    cd infrastructure

    if [ ! -f "terraform.tfstate" ]; then
        print_error "Terraform state not found. Please run 'terraform apply' first."
        exit 1
    fi

    # Get bucket names from Terraform outputs
    APP_BUCKET_NAME=$(terraform output -raw app_bucket_name 2>/dev/null || echo "")
    LOGS_BUCKET_NAME=$(terraform output -raw logs_bucket_name 2>/dev/null || echo "")
    AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "")

    if [ -z "$APP_BUCKET_NAME" ] || [ -z "$LOGS_BUCKET_NAME" ] || [ -z "$AWS_REGION" ]; then
        print_error "Could not get Terraform outputs. Please run 'terraform apply' first."
        exit 1
    fi

    print_success "Retrieved Terraform outputs"
    print_status "App Bucket: $APP_BUCKET_NAME"
    print_status "Logs Bucket: $LOGS_BUCKET_NAME"
    print_status "AWS Region: $AWS_REGION"

    cd ..
}

# Function to test S3 access
test_s3_access() {
    local bucket_name=$1
    local test_file="test-$(date +%s).txt"
    local test_content="S3 access test - $(date)"

    print_status "Testing S3 access to bucket: $bucket_name"

    # Create test file
    echo "$test_content" > "$test_file"

    # Upload test file
    if aws s3 cp "$test_file" "s3://$bucket_name/" >/dev/null 2>&1; then
        print_success "Successfully uploaded test file to s3://$bucket_name/"
    else
        print_error "Failed to upload test file to s3://$bucket_name/"
        rm -f "$test_file"
        return 1
    fi

    # Download test file
    if aws s3 cp "s3://$bucket_name/$test_file" "${test_file}.downloaded" >/dev/null 2>&1; then
        print_success "Successfully downloaded test file from s3://$bucket_name/"
    else
        print_error "Failed to download test file from s3://$bucket_name/"
        rm -f "$test_file" "${test_file}.downloaded"
        return 1
    fi

    # Verify content
    if [ "$(cat "$test_file")" = "$(cat "${test_file}.downloaded")" ]; then
        print_success "File content verification passed"
    else
        print_error "File content verification failed"
        rm -f "$test_file" "${test_file}.downloaded"
        return 1
    fi

    # Delete test file from S3
    if aws s3 rm "s3://$bucket_name/$test_file" >/dev/null 2>&1; then
        print_success "Successfully deleted test file from s3://$bucket_name/"
    else
        print_warning "Failed to delete test file from s3://$bucket_name/"
    fi

    # Clean up local files
    rm -f "$test_file" "${test_file}.downloaded"
}

# Function to create S3 directory structure
create_s3_structure() {
    local bucket_name=$1
    local prefix=$2

    print_status "Creating directory structure in s3://$bucket_name/$prefix"

    # Create common directories
    aws s3api put-object --bucket "$bucket_name" --key "$prefix/input/" >/dev/null 2>&1 || true
    aws s3api put-object --bucket "$bucket_name" --key "$prefix/output/" >/dev/null 2>&1 || true
    aws s3api put-object --bucket "$bucket_name" --key "$prefix/temp/" >/dev/null 2>&1 || true
    aws s3api put-object --bucket "$bucket_name" --key "$prefix/logs/" >/dev/null 2>&1 || true

    print_success "Created directory structure in s3://$bucket_name/$prefix"
}

# Function to generate S3 sync script
generate_sync_script() {
    local script_name="sync-s3.sh"
    
    cat > "$script_name" << 'EOF'
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
EOF

    chmod +x "$script_name"
    print_success "Generated sync script: $script_name"
}

# Function to create S3 configuration file
create_s3_config() {
    local config_file="s3-config.env"
    
    cat > "$config_file" << EOF
# S3 Configuration
S3_APP_BUCKET=$APP_BUCKET_NAME
S3_LOGS_BUCKET=$LOGS_BUCKET_NAME
S3_REGION=$AWS_REGION
S3_DATA_PREFIX=data
S3_LOGS_PREFIX=logs
EOF

    print_success "Created S3 configuration file: $config_file"
    print_status "You can source this file to set environment variables:"
    print_status "  source $config_file"
}

# Function to install AWS CLI if not present
install_aws_cli() {
    if command_exists aws; then
        print_status "AWS CLI is already installed"
        return 0
    fi

    print_status "Installing AWS CLI..."

    if command_exists curl; then
        # Install AWS CLI v2
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip -q awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
        print_success "AWS CLI v2 installed successfully"
    elif command_exists apt-get; then
        # Install AWS CLI v1 (Ubuntu/Debian)
        sudo apt-get update
        sudo apt-get install -y awscli
        print_success "AWS CLI v1 installed successfully"
    else
        print_error "Could not install AWS CLI automatically. Please install it manually."
        print_status "Installation guide: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
}

# Main execution
main() {
    print_status "Starting S3 setup..."

    # Check if AWS CLI is installed and configured
    if ! command_exists aws; then
        print_warning "AWS CLI not found. Attempting to install..."
        install_aws_cli
    fi

    check_aws_config
    get_terraform_outputs

    # Test S3 access
    print_status "Testing S3 access..."
    if test_s3_access "$APP_BUCKET_NAME"; then
        print_success "S3 access test passed for app bucket"
    else
        print_error "S3 access test failed for app bucket"
        exit 1
    fi

    if test_s3_access "$LOGS_BUCKET_NAME"; then
        print_success "S3 access test passed for logs bucket"
    else
        print_error "S3 access test failed for logs bucket"
        exit 1
    fi

    # Create S3 directory structure
    create_s3_structure "$APP_BUCKET_NAME" "data"
    create_s3_structure "$LOGS_BUCKET_NAME" ""

    # Generate sync script
    generate_sync_script

    # Create S3 configuration file
    create_s3_config

    print_success "S3 setup completed successfully!"
    print_status ""
    print_status "Next steps:"
    print_status "1. Source the configuration: source s3-config.env"
    print_status "2. Use the sync script: ./sync-s3.sh up|down|logs"
    print_status "3. Test S3 access from EC2 instance"
}

# Run main function
main "$@" 