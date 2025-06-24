# =============================================================================
# TERRAFORM EC2 PROJECT - SECURE MAKEFILE
# =============================================================================

# Default environment
ENV ?= dev

# Colors for output
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
RESET := \033[0m

# SSH key paths (now in parent directory)
SSH_KEY_DIR := ../.ssh
SSH_KEY_NAME := terraform-ec2-key
SSH_PRIVATE_KEY := $(SSH_KEY_DIR)/$(SSH_KEY_NAME)
SSH_PUBLIC_KEY := $(SSH_PRIVATE_KEY).pub

# Default target
.DEFAULT_GOAL := help

# =============================================================================
# PHONY TARGETS
# =============================================================================
.PHONY: help init plan apply destroy outputs clean tf-status ec2-status ec2-start ec2-stop ec2-connect ssh-keys check-keys security-check

# =============================================================================
# HELP
# =============================================================================

help: ## Show this help message
	@echo "$(BLUE)🔐 Secure Terraform EC2 Development Server$(RESET)"
	@echo ""
	@echo "$(RED)🔒 SECURITY FEATURES:$(RESET)"
	@echo "  • SSH keys are NOT stored in Terraform state"
	@echo "  • Private keys remain local and secure"
	@echo "  • Keys are auto-generated outside Terraform"
	@echo ""
	@echo "$(YELLOW)SECURE SETUP COMMANDS:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## 🔐.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(RESET) %s\n", $$1, $$2}' | sed 's/🔐 //'
	@echo ""
	@echo "$(YELLOW)TERRAFORM COMMANDS:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## 🔧.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(RESET) %s\n", $$1, $$2}' | sed 's/🔧 //'
	@echo ""
	@echo "$(YELLOW)EC2 INSTANCE COMMANDS:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## 💻.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(RESET) %s\n", $$1, $$2}' | sed 's/💻 //'
	@echo ""
	@echo "$(BLUE)🚀 Quick Start (Secure):$(RESET)"
	@echo "  make ssh-keys        # Generate secure SSH keys"
	@echo "  make apply           # Deploy infrastructure"
	@echo "  make ec2-connect     # Connect to server"
	@echo "  make destroy         # Clean up everything"

# =============================================================================
# SECURE SSH KEY MANAGEMENT
# =============================================================================

ssh-keys: ## 🔐 Generate secure SSH keys (outside Terraform state)
	@echo "$(BLUE)🔑 Generating secure SSH keys...$(RESET)"
	@mkdir -p $(SSH_KEY_DIR)
	@./scripts/generate-ssh-keys.sh
	@echo "$(GREEN)✅ SSH keys generated securely!$(RESET)"

check-keys: ## 🔐 Check if SSH keys exist and are properly configured
	@echo "$(YELLOW)Checking SSH key configuration...$(RESET)"
	@if [ -f "$(SSH_PRIVATE_KEY)" ] && [ -f "$(SSH_PUBLIC_KEY)" ]; then \
		echo "$(GREEN)✅ SSH private key: $(SSH_PRIVATE_KEY)$(RESET)"; \
		echo "$(GREEN)✅ SSH public key: $(SSH_PUBLIC_KEY)$(RESET)"; \
		if [ -f "ssh_public_key.auto.tfvars" ]; then \
			echo "$(GREEN)✅ Terraform variable file: ssh_public_key.auto.tfvars$(RESET)"; \
		else \
			echo "$(RED)❌ Missing Terraform variable file$(RESET)"; \
		fi; \
	else \
		echo "$(RED)❌ SSH keys not found. Run 'make ssh-keys' first$(RESET)"; \
	fi

# =============================================================================
# TERRAFORM COMMANDS - SECURE VERSION
# =============================================================================

init: check-keys ## 🔧 Initialize Terraform (with security check)
	@echo "$(YELLOW)Initializing Terraform...$(RESET)"
	@terraform init

plan: check-keys ## 🔧 Show Terraform plan (with security check)
	@echo "$(YELLOW)Planning deployment...$(RESET)"
	@if [ -f "environments/$(ENV)/terraform.tfvars" ]; then \
		terraform plan -var-file="environments/$(ENV)/terraform.tfvars"; \
	else \
		terraform plan; \
	fi

apply: check-keys ## 🔧 Apply Terraform configuration (with security check)
	@echo "$(YELLOW)Applying Terraform configuration...$(RESET)"
	@if [ ! -f "$(SSH_PRIVATE_KEY)" ]; then \
		echo "$(RED)❌ SSH keys not found. Generating them now...$(RESET)"; \
		$(MAKE) ssh-keys; \
	fi
	@if [ -f "environments/$(ENV)/terraform.tfvars" ]; then \
		terraform apply -var-file="environments/$(ENV)/terraform.tfvars"; \
	else \
		terraform apply; \
	fi

destroy: ## 🔧 Destroy all infrastructure
	@echo "$(RED)⚠️  WARNING: This will destroy all infrastructure!$(RESET)"
	@read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ]
	@if [ -f "environments/$(ENV)/terraform.tfvars" ]; then \
		terraform destroy -var-file="environments/$(ENV)/terraform.tfvars"; \
	else \
		terraform destroy; \
	fi

outputs: ## 🔧 Show Terraform outputs
	@echo "$(YELLOW)Terraform Outputs:$(RESET)"
	@terraform output

tf-status: ## 🔧 Show Terraform state status (secure)
	@echo "$(YELLOW)Terraform State Status:$(RESET)"
	@if [ -f "terraform.tfstate" ]; then \
		echo "$(GREEN)✅ State file exists$(RESET)"; \
		echo "Resources: $$(terraform state list | wc -l)"; \
		echo "$(BLUE)🔒 SSH private keys are NOT in state (secure)$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  No state file found$(RESET)"; \
	fi

clean: ## 🔧 Clean Terraform temporary files (keeps SSH keys safe)
	@echo "$(YELLOW)Cleaning Terraform files...$(RESET)"
	@rm -rf .terraform/
	@rm -f .terraform.lock.hcl
	@rm -f terraform.tfplan
	@rm -f terraform.tfstate.backup
	@echo "$(GREEN)✅ Cleaned temporary files$(RESET)"
	@echo "$(BLUE)🔒 SSH keys preserved safely$(RESET)"

# =============================================================================
# EC2 INSTANCE COMMANDS - SECURE VERSION
# =============================================================================

ec2-connect: ## 💻 Connect to EC2 instance via SSH (using secure keys)
	@echo "$(YELLOW)Connecting to EC2 instance...$(RESET)"
	@if [ ! -f "$(SSH_PRIVATE_KEY)" ]; then \
		echo "$(RED)❌ SSH private key not found at $(SSH_PRIVATE_KEY)$(RESET)"; \
		echo "$(YELLOW)Run 'make ssh-keys' to generate keys$(RESET)"; \
		exit 1; \
	fi
	@if terraform output instance_public_ip > /dev/null 2>&1; then \
		IP=$$(terraform output -raw instance_public_ip); \
		echo "$(GREEN)Connecting to: ubuntu@$$IP$(RESET)"; \
		echo "$(BLUE)Using secure SSH key: $(SSH_PRIVATE_KEY)$(RESET)"; \
		ssh -i $(SSH_PRIVATE_KEY) -o StrictHostKeyChecking=no ubuntu@$$IP; \
	else \
		echo "$(RED)❌ No instance found. Deploy infrastructure first.$(RESET)"; \
	fi

ec2-status: ## 💻 Check EC2 instance status
	@echo "$(YELLOW)Checking EC2 instance status...$(RESET)"
	@if terraform output instance_id > /dev/null 2>&1; then \
		INSTANCE_ID=$$(terraform output -raw instance_id); \
		STATE=$$(aws ec2 describe-instances --instance-ids $$INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || echo "unknown"); \
		IP=$$(aws ec2 describe-instances --instance-ids $$INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text 2>/dev/null || echo "none"); \
		echo "$(BLUE)Instance ID:$(RESET) $$INSTANCE_ID"; \
		echo "$(BLUE)Status:$(RESET) $$STATE"; \
		echo "$(BLUE)Public IP:$(RESET) $$IP"; \
		echo "$(GREEN)🔒 SSH Connection:$(RESET) ssh -i $(SSH_PRIVATE_KEY) ubuntu@$$IP"; \
	else \
		echo "$(RED)❌ No instance found. Deploy infrastructure first.$(RESET)"; \
	fi

ec2-stop: ## 💻 Stop EC2 instance (saves costs)
	@echo "$(YELLOW)Stopping EC2 instance...$(RESET)"
	@if terraform output instance_id > /dev/null 2>&1; then \
		INSTANCE_ID=$$(terraform output -raw instance_id); \
		aws ec2 stop-instances --instance-ids $$INSTANCE_ID > /dev/null; \
		echo "$(GREEN)✅ Instance $$INSTANCE_ID stopped$(RESET)"; \
		echo "$(BLUE)💡 Instance will save costs while stopped$(RESET)"; \
	else \
		echo "$(RED)❌ No instance found. Deploy infrastructure first.$(RESET)"; \
	fi

ec2-start: ## 💻 Start EC2 instance
	@echo "$(YELLOW)Starting EC2 instance...$(RESET)"
	@if terraform output instance_id > /dev/null 2>&1; then \
		INSTANCE_ID=$$(terraform output -raw instance_id); \
		aws ec2 start-instances --instance-ids $$INSTANCE_ID > /dev/null; \
		echo "$(BLUE)Waiting for instance to be ready...$(RESET)"; \
		aws ec2 wait instance-running --instance-ids $$INSTANCE_ID; \
		NEW_IP=$$(aws ec2 describe-instances --instance-ids $$INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text); \
		echo "$(GREEN)✅ Instance started!$(RESET)"; \
		echo "$(BLUE)New IP:$(RESET) $$NEW_IP"; \
		echo "$(GREEN)🔒 SSH Command:$(RESET) ssh -i $(SSH_PRIVATE_KEY) ubuntu@$$NEW_IP"; \
		echo "$(YELLOW)💡 IP address may have changed after restart$(RESET)"; \
	else \
		echo "$(RED)❌ No instance found. Deploy infrastructure first.$(RESET)"; \
	fi

# =============================================================================
# SECURITY VALIDATION COMMANDS
# =============================================================================

security-check: ## 🔐 Run comprehensive security check
	@echo "$(BLUE)🔒 Running Security Validation...$(RESET)"
	@echo "$(YELLOW)Checking for secrets in Terraform state...$(RESET)"
	@if [ -f "terraform.tfstate" ]; then \
		if grep -q "private_key_pem\|BEGIN.*PRIVATE.*KEY" terraform.tfstate 2>/dev/null; then \
			echo "$(RED)❌ SECURITY RISK: Private keys found in Terraform state!$(RESET)"; \
			exit 1; \
		else \
			echo "$(GREEN)✅ No private keys found in Terraform state$(RESET)"; \
		fi; \
	else \
		echo "$(YELLOW)⚠️  No state file to check$(RESET)"; \
	fi
	@echo "$(YELLOW)Checking SSH key permissions...$(RESET)"
	@if [ -f "$(SSH_PRIVATE_KEY)" ]; then \
		PERMS=$$(stat -c %a $(SSH_PRIVATE_KEY) 2>/dev/null || stat -f %A $(SSH_PRIVATE_KEY) 2>/dev/null); \
		if [ "$$PERMS" = "600" ]; then \
			echo "$(GREEN)✅ SSH private key has correct permissions (600)$(RESET)"; \
		else \
			echo "$(YELLOW)⚠️  SSH private key permissions: $$PERMS (should be 600)$(RESET)"; \
		fi; \
	fi
	@echo "$(GREEN)🔒 Security check completed!$(RESET)"