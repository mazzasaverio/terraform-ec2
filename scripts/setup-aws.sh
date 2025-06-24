#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔧 AWS Setup for ECR Deployment${NC}"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found.${NC}"
    echo -e "${YELLOW}Installing AWS CLI...${NC}"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        sudo installer -pkg AWSCLIV2.pkg -target /
        rm AWSCLIV2.pkg
    else
        # Linux
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    fi
fi

echo -e "${GREEN}✅ AWS CLI installed${NC}"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${YELLOW}🔑 AWS credentials not configured. Let's set them up...${NC}"
    echo ""
    echo -e "${BLUE}You'll need:${NC}"
    echo -e "  - AWS Access Key ID"
    echo -e "  - AWS Secret Access Key"
    echo -e "  - Default region (e.g., eu-west-1, us-east-1)"
    echo ""
    aws configure
fi

# Verify access
echo -e "${YELLOW}🔍 Verifying AWS access...${NC}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)

echo -e "${GREEN}✅ AWS Account: $ACCOUNT_ID${NC}"
echo -e "${GREEN}✅ Region: $REGION${NC}"
echo -e "${GREEN}✅ User: $USER_ARN${NC}"

# Check required permissions
echo -e "${YELLOW}🔍 Checking ECR permissions...${NC}"
if aws ecr describe-repositories --region $REGION &> /dev/null; then
    echo -e "${GREEN}✅ ECR access confirmed${NC}"
else
    echo -e "${YELLOW}⚠️ ECR access may be limited, but proceeding...${NC}"
fi

echo ""
echo -e "${GREEN}🎉 AWS setup completed!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. ${YELLOW}cd infrastructure && make ssh-keys${NC} (generate SSH keys)"
echo -e "  2. ${YELLOW}cd infrastructure && make apply${NC} (deploy infrastructure)"
echo -e "  3. ${YELLOW}cd backend && ./deploy-simple.sh${NC} (deploy backend via ECR)" 