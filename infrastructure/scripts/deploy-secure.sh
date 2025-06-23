#!/bin/bash
# =============================================================================
# SECURE DEPLOYMENT SCRIPT WITH SSH KEY GENERATION
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo -e "${BLUE}🚀 Secure Infrastructure Deployment${NC}"
echo "===================================="

# Step 1: Generate SSH keys if they don't exist
if [[ ! -f "${PROJECT_ROOT}/.ssh/terraform-ec2-key" ]]; then
    echo -e "${YELLOW}🔑 Generating SSH keys...${NC}"
    "${SCRIPT_DIR}/generate-ssh-keys.sh"
else
    echo -e "${GREEN}✅ SSH keys already exist${NC}"
fi

# Step 2: Check if Terraform is initialized
if [[ ! -d "${PROJECT_ROOT}/.terraform" ]]; then
    echo -e "${BLUE}🔧 Initializing Terraform...${NC}"
    cd "${PROJECT_ROOT}"
    terraform init
fi

# Step 3: Validate configuration
echo -e "${BLUE}🔍 Validating Terraform configuration...${NC}"
cd "${PROJECT_ROOT}"
terraform validate

# Step 4: Plan the deployment
echo -e "${BLUE}📋 Planning deployment...${NC}"
terraform plan -out=deployment.tfplan

# Step 5: Apply (with confirmation)
echo -e "${YELLOW}⚠️  Ready to deploy infrastructure...${NC}"
read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🚀 Deploying infrastructure...${NC}"
    terraform apply deployment.tfplan
    
    # Clean up plan file
    rm -f deployment.tfplan
    
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
    echo
    echo -e "${BLUE}📍 Connection Info:${NC}"
    terraform output -json | jq -r '.ssh_connection_command.value // "SSH command not available"'
else
    echo -e "${YELLOW}❌ Deployment cancelled${NC}"
    rm -f deployment.tfplan
fi 