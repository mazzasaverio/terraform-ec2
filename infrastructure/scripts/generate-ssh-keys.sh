#!/bin/bash
# =============================================================================
# SECURE SSH KEY GENERATION SCRIPT
# Generates SSH keys outside of Terraform to keep private keys secure
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# SSH key paths (now in parent directory)
SSH_KEY_DIR="../.ssh"
SSH_KEY_NAME="terraform-ec2-key"
SSH_PRIVATE_KEY="$SSH_KEY_DIR/$SSH_KEY_NAME"
SSH_PUBLIC_KEY="$SSH_PRIVATE_KEY.pub"

echo -e "${BLUE}🔑 Generating SSH keys for Terraform EC2...${NC}"

# Create SSH directory if it doesn't exist
mkdir -p "$SSH_KEY_DIR"

# Generate SSH key pair
if [ ! -f "$SSH_PRIVATE_KEY" ]; then
    echo -e "${YELLOW}Generating new SSH key pair...${NC}"
    ssh-keygen -t rsa -b 4096 -f "$SSH_PRIVATE_KEY" -N "" -C "terraform-ec2-key"
    echo -e "${GREEN}✅ SSH key pair generated${NC}"
else
    echo -e "${YELLOW}SSH key pair already exists${NC}"
fi

# Set correct permissions
chmod 600 "$SSH_PRIVATE_KEY"
chmod 644 "$SSH_PUBLIC_KEY"

echo -e "${GREEN}✅ SSH key permissions set correctly${NC}"

# Create Terraform variable file
echo -e "${YELLOW}Creating Terraform variable file...${NC}"
cat > ssh_public_key.auto.tfvars << EOF
# Auto-generated SSH public key for EC2 instance
# Generated on: $(date)
# DO NOT EDIT - This file is auto-generated

ssh_public_key = "$(cat "$SSH_PUBLIC_KEY")"
EOF

echo -e "${GREEN}✅ Terraform variable file created: ssh_public_key.auto.tfvars${NC}"

echo ""
echo -e "${GREEN}🎉 SSH key setup completed!${NC}"
echo -e "${BLUE}Files created:${NC}"
echo -e "   Private key: ${SSH_PRIVATE_KEY}"
echo -e "   Public key:  ${SSH_PUBLIC_KEY}"
echo -e "   Terraform:   ssh_public_key.auto.tfvars"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo -e "  • Private key is ${RED}NOT${NC} in Terraform state (secure)"
echo -e "  • Keys are stored in ${SSH_KEY_DIR}/ (excluded from git)"
echo -e "  • Use: ssh -i ${SSH_PRIVATE_KEY} ubuntu@EC2_IP" 