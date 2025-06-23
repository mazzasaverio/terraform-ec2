#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deploying FastAPI Backend to EC2...${NC}"

# Get EC2 IP from Terraform
if [ ! -d "../infrastructure" ]; then
    echo -e "${RED}❌ Infrastructure directory not found. Run from backend folder.${NC}"
    exit 1
fi

echo -e "${YELLOW}📡 Getting EC2 instance information...${NC}"
EC2_IP=$(cd ../infrastructure && terraform output -raw instance_public_ip 2>/dev/null || echo "")
SSH_KEY="../infrastructure/.ssh/terraform-ec2-key"

if [ -z "$EC2_IP" ]; then
    echo -e "${RED}❌ Could not get EC2 IP. Make sure infrastructure is deployed.${NC}"
    echo -e "${YELLOW}💡 Run: cd ../infrastructure && make apply${NC}"
    exit 1
fi

echo -e "${GREEN}✅ EC2 Instance found: $EC2_IP${NC}"

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo -e "${RED}❌ SSH key not found at $SSH_KEY${NC}"
    echo -e "${YELLOW}💡 Run: cd ../infrastructure && make ssh-keys${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Using secure SSH key: $SSH_KEY${NC}"

echo -e "${YELLOW}📦 Building Docker image...${NC}"
docker build -t simple-backend:latest .

echo -e "${YELLOW}📤 Preparing deployment package...${NC}"
docker save simple-backend:latest | gzip > /tmp/backend.tar.gz

# Create deployment directory structure
echo -e "${YELLOW}📁 Creating deployment files...${NC}"
cat > /tmp/deploy-backend.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

echo "🐳 Loading Docker image..."
docker load < /tmp/backend.tar.gz

echo "📁 Creating project directories..."
mkdir -p ~/fastapi-app/{data/{input,output,temp},logs}
cd ~/fastapi-app

echo "📋 Setting up environment..."
cat > .env << 'ENV_FILE'
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO
API_HOST=0.0.0.0
API_PORT=8000
DATA_INPUT_PATH=/app/data/input
DATA_OUTPUT_PATH=/app/data/output
DATA_TEMP_PATH=/app/data/temp
SECRET_KEY=production_secret_key_$(openssl rand -hex 32)
ALLOWED_HOSTS=*
ENV_FILE

echo "🔄 Stopping existing containers..."
docker stop simple-backend 2>/dev/null || true
docker rm simple-backend 2>/dev/null || true

echo "🚀 Starting new container..."
docker run -d \
  --name simple-backend \
  --restart unless-stopped \
  -p 8000:8000 \
  --env-file .env \
  -v ~/fastapi-app/data:/app/data \
  -v ~/fastapi-app/logs:/app/logs \
  simple-backend:latest

echo "⏳ Waiting for container to be ready..."
sleep 15

echo "🏥 Health check..."
for i in {1..10}; do
  if curl -s http://localhost:8000/health >/dev/null; then
    echo "✅ Backend is healthy!"
    break
  fi
  echo "⏳ Waiting for backend... ($i/10)"
  sleep 3
done

echo "📊 Container status:"
docker ps | grep simple-backend || echo "❌ Container not running"

echo "🧹 Cleanup..."
rm /tmp/backend.tar.gz /tmp/deploy-backend.sh

echo "✅ Deployment completed successfully!"
echo "🌐 Backend URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000"
DEPLOY_SCRIPT

chmod +x /tmp/deploy-backend.sh

echo -e "${YELLOW}🔄 Deploying to EC2 ($EC2_IP)...${NC}"
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no /tmp/backend.tar.gz ubuntu@$EC2_IP:/tmp/
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no /tmp/deploy-backend.sh ubuntu@$EC2_IP:/tmp/

echo -e "${YELLOW}⚙️ Running deployment on EC2...${NC}"
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@$EC2_IP 'bash /tmp/deploy-backend.sh'

# Cleanup local temp files
rm /tmp/backend.tar.gz /tmp/deploy-backend.sh

echo ""
echo -e "${GREEN}🎉 Backend deployed successfully!${NC}"
echo -e "${BLUE}🌐 API Base URL: http://$EC2_IP:8000${NC}"
echo -e "${BLUE}📋 Interactive Docs: http://$EC2_IP:8000/docs${NC}"
echo -e "${BLUE}📖 ReDoc: http://$EC2_IP:8000/redoc${NC}"
echo ""
echo -e "${YELLOW}🧪 Quick Tests:${NC}"
echo -e "  ${GREEN}curl http://$EC2_IP:8000/${NC}"
echo -e "  ${GREEN}curl http://$EC2_IP:8000/health${NC}"
echo -e "  ${GREEN}curl -X POST http://$EC2_IP:8000/messages -H 'Content-Type: application/json' -d '{\"message\":\"Hello from EC2!\",\"user_id\":\"test\"}'${NC}"
echo ""
echo -e "${YELLOW}📊 Monitor logs:${NC}"
echo -e "  ${GREEN}ssh -i $SSH_KEY ubuntu@$EC2_IP 'docker logs simple-backend -f'${NC}" 