#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Simple ECR Deploy for FastAPI Backend${NC}"

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}❌ Dockerfile not found. Run from backend directory.${NC}"
    exit 1
fi

# Get AWS account ID and region
echo -e "${YELLOW}📡 Getting AWS information...${NC}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)

if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ]; then
    echo -e "${RED}❌ AWS not configured properly${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS Account: $AWS_ACCOUNT_ID${NC}"
echo -e "${GREEN}✅ AWS Region: $AWS_REGION${NC}"

# Get ECR repository name from Terraform
echo -e "${YELLOW}📋 Getting ECR repository info...${NC}"
ECR_REPO_NAME=$(cd ../infrastructure && terraform output -raw ecr_repository_name)
ECR_URI=$(cd ../infrastructure && terraform output -raw ecr_repository_url)
IMAGE_TAG="latest"

echo -e "${GREEN}✅ ECR Repository: $ECR_REPO_NAME${NC}"
echo -e "${GREEN}✅ ECR URI: $ECR_URI${NC}"

echo -e "${YELLOW}🐳 Building Docker image...${NC}"
docker build -t simple-backend:$IMAGE_TAG .

echo -e "${YELLOW}🏷️ Tagging for ECR...${NC}"
docker tag simple-backend:$IMAGE_TAG $ECR_URI:$IMAGE_TAG

echo -e "${YELLOW}🔐 Authenticating with ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

echo -e "${YELLOW}📤 Pushing to ECR...${NC}"
docker push $ECR_URI:$IMAGE_TAG

echo -e "${YELLOW}📡 Getting EC2 instance info...${NC}"
EC2_IP=$(cd ../infrastructure && terraform output -raw instance_public_ip 2>/dev/null || echo "")
SSH_KEY="../.ssh/terraform-ec2-key"

if [ -z "$EC2_IP" ]; then
    echo -e "${RED}❌ EC2 instance not found. Deploy infrastructure first.${NC}"
    exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
    echo -e "${RED}❌ SSH key not found at $SSH_KEY${NC}"
    exit 1
fi

echo -e "${GREEN}✅ EC2 Instance: $EC2_IP${NC}"

echo -e "${YELLOW}🔄 Deploying to EC2...${NC}"

# Create deployment script for EC2
cat > /tmp/deploy-on-ec2.sh << EOF
#!/bin/bash
set -e

echo "🔐 Authenticating with ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}

echo "🛑 Stopping existing container..."
docker stop simple-backend 2>/dev/null || true
docker rm simple-backend 2>/dev/null || true

echo "📥 Pulling latest image..."
docker pull ${ECR_URI}:${IMAGE_TAG}

echo "🚀 Starting new container..."
docker run -d \\
  --name simple-backend \\
  --restart unless-stopped \\
  -p 8000:8000 \\
  -e ENVIRONMENT=production \\
  -e LOG_LEVEL=INFO \\
  ${ECR_URI}:${IMAGE_TAG}

echo "⏳ Waiting for container to start..."
sleep 10

echo "🏥 Health check..."
if curl -s http://localhost:8000/health >/dev/null; then
    echo "✅ Backend is healthy!"
    echo "🌐 Backend URL: http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000"
else
    echo "❌ Health check failed"
    docker logs simple-backend
    exit 1
fi
EOF

# Copy and execute on EC2
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no /tmp/deploy-on-ec2.sh ubuntu@$EC2_IP:/tmp/
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$EC2_IP 'chmod +x /tmp/deploy-on-ec2.sh && /tmp/deploy-on-ec2.sh'

# Cleanup
rm /tmp/deploy-on-ec2.sh

echo ""
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}🌐 API URL: http://$EC2_IP:8000${NC}"
echo -e "${BLUE}📋 Docs: http://$EC2_IP:8000/docs${NC}"
echo ""
echo -e "${YELLOW}🧪 Quick test:${NC}"
echo -e "  ${GREEN}curl http://$EC2_IP:8000/health${NC}" 