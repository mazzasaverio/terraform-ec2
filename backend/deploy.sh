#!/bin/bash
set -e

echo "🚀 Deploying Simple Backend to EC2..."

# Get EC2 IP from Terraform
if [ ! -d "../infrastructure" ]; then
    echo "❌ Infrastructure directory not found. Run from backend folder."
    exit 1
fi

EC2_IP=$(cd ../infrastructure && terraform output -raw instance_public_ip 2>/dev/null || echo "")
SSH_KEY="~/.ssh/data-ingestion-dev-key.pem"

if [ -z "$EC2_IP" ]; then
    echo "❌ Could not get EC2 IP. Make sure infrastructure is deployed."
    exit 1
fi

echo "📦 Building Docker image..."
docker build -t simple-backend:latest .

echo "📤 Saving and transferring image..."
docker save simple-backend:latest | gzip > /tmp/backend.tar.gz

echo "🔄 Deploying to EC2 ($EC2_IP)..."
scp -i $SSH_KEY /tmp/backend.tar.gz ubuntu@$EC2_IP:/tmp/
scp -i $SSH_KEY docker-compose.prod.yml ubuntu@$EC2_IP:/home/ubuntu/

ssh -i $SSH_KEY ubuntu@$EC2_IP << 'EOF'
    echo "Loading Docker image..."
    docker load < /tmp/backend.tar.gz
    
    echo "Stopping existing container..."
    docker compose -f docker-compose.prod.yml down || true
    
    echo "Starting new container..."
    docker compose -f docker-compose.prod.yml up -d
    
    echo "Waiting for container to be ready..."
    sleep 10
    
    echo "Checking container status..."
    docker compose -f docker-compose.prod.yml ps
    
    echo "Cleanup..."
    rm /tmp/backend.tar.gz
    
    echo "✅ Deployment completed!"
EOF

# Cleanup local temp file
rm /tmp/backend.tar.gz

echo "🎉 Backend deployed successfully!"
echo "🌐 Access at: http://$EC2_IP:8000"
echo "📋 Docs at: http://$EC2_IP:8000/docs"
echo ""
echo "🧪 Test endpoints:"
echo "  curl http://$EC2_IP:8000/"
echo "  curl http://$EC2_IP:8000/health"
echo "  curl -X POST http://$EC2_IP:8000/messages -H 'Content-Type: application/json' -d '{\"message\":\"Hello World\",\"user_id\":\"test\"}'" 