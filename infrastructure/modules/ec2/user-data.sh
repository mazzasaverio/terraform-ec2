#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt-get install -y unzip
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Configure AWS CLI region
aws configure set region ${aws_region}

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create ECR login helper script
cat > /usr/local/bin/ecr-login << 'EOF'
#!/bin/bash
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.${aws_region}.amazonaws.com
EOF
chmod +x /usr/local/bin/ecr-login

# Create S3 helper scripts
cat > /usr/local/bin/s3-sync << 'EOF'
#!/bin/bash
# S3 sync helper script
# Usage: s3-sync [up|down|logs]

# Get bucket names from instance metadata or environment
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Default bucket names (will be updated by Terraform outputs)
APP_BUCKET="${name_prefix}-app-data-$(aws sts get-caller-identity --query Account --output text | tail -c 8)"
LOGS_BUCKET="${name_prefix}-logs-$(aws sts get-caller-identity --query Account --output text | tail -c 8)"

case "$1" in
    "up")
        echo "Syncing local data to S3..."
        aws s3 sync /home/ubuntu/data/ s3://$APP_BUCKET/data/ --exclude "*.tmp" --exclude "*.temp"
        echo "Data synced to S3"
        ;;
    "down")
        echo "Syncing S3 data to local..."
        aws s3 sync s3://$APP_BUCKET/data/ /home/ubuntu/data/ --exclude "*.tmp" --exclude "*.temp"
        echo "Data synced from S3"
        ;;
    "logs")
        echo "Syncing logs to S3..."
        aws s3 sync /home/ubuntu/logs/ s3://$LOGS_BUCKET/ --exclude "*.tmp" --exclude "*.temp"
        echo "Logs synced to S3"
        ;;
    *)
        echo "Usage: s3-sync {up|down|logs}"
        echo "  up   - Sync local data to S3"
        echo "  down - Sync S3 data to local"
        echo "  logs - Sync logs to S3"
        exit 1
        ;;
esac
EOF
chmod +x /usr/local/bin/s3-sync

# Create S3 test script
cat > /usr/local/bin/s3-test << 'EOF'
#!/bin/bash
# S3 access test script

AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Default bucket names
APP_BUCKET="${name_prefix}-app-data-$(aws sts get-caller-identity --query Account --output text | tail -c 8)"
LOGS_BUCKET="${name_prefix}-logs-$(aws sts get-caller-identity --query Account --output text | tail -c 8)"

echo "Testing S3 access..."

# Test app bucket
echo "Testing app bucket: $APP_BUCKET"
if aws s3 ls s3://$APP_BUCKET/ >/dev/null 2>&1; then
    echo "✓ App bucket access successful"
else
    echo "✗ App bucket access failed"
fi

# Test logs bucket
echo "Testing logs bucket: $LOGS_BUCKET"
if aws s3 ls s3://$LOGS_BUCKET/ >/dev/null 2>&1; then
    echo "✓ Logs bucket access successful"
else
    echo "✗ Logs bucket access failed"
fi

# Test upload/download
TEST_FILE="test-$(date +%s).txt"
echo "S3 test - $(date)" > $TEST_FILE

echo "Testing upload to app bucket..."
if aws s3 cp $TEST_FILE s3://$APP_BUCKET/ >/dev/null 2>&1; then
    echo "✓ Upload successful"
    
    echo "Testing download from app bucket..."
    if aws s3 cp s3://$APP_BUCKET/$TEST_FILE $TEST_FILE.downloaded >/dev/null 2>&1; then
        echo "✓ Download successful"
        
        if [ "$(cat $TEST_FILE)" = "$(cat $TEST_FILE.downloaded)" ]; then
            echo "✓ Content verification passed"
        else
            echo "✗ Content verification failed"
        fi
        
        rm -f $TEST_FILE.downloaded
    else
        echo "✗ Download failed"
    fi
    
    # Clean up
    aws s3 rm s3://$APP_BUCKET/$TEST_FILE >/dev/null 2>&1 || true
else
    echo "✗ Upload failed"
fi

rm -f $TEST_FILE
echo "S3 test completed"
EOF
chmod +x /usr/local/bin/s3-test

# Create data and logs directories
mkdir -p /home/ubuntu/data/{input,output,temp}
mkdir -p /home/ubuntu/logs
chown -R ubuntu:ubuntu /home/ubuntu/data /home/ubuntu/logs

# Setup aliases for ubuntu user
echo 'alias ecr-login="/usr/local/bin/ecr-login"' >> /home/ubuntu/.bashrc
echo 'alias s3-sync="/usr/local/bin/s3-sync"' >> /home/ubuntu/.bashrc
echo 'alias s3-test="/usr/local/bin/s3-test"' >> /home/ubuntu/.bashrc

# Create S3 configuration file
cat > /home/ubuntu/s3-config.env << EOF
# S3 Configuration for EC2 instance
S3_APP_BUCKET=${name_prefix}-app-data-$(aws sts get-caller-identity --query Account --output text | tail -c 8)
S3_LOGS_BUCKET=${name_prefix}-logs-$(aws sts get-caller-identity --query Account --output text | tail -c 8)
S3_REGION=${aws_region}
S3_DATA_PREFIX=data
S3_LOGS_PREFIX=logs
EOF

chown ubuntu:ubuntu /home/ubuntu/s3-config.env

# Reboot to ensure all changes take effect
reboot 