# =============================================================================
# TERRAFORM EC2 PROJECT - CLEAN MAKEFILE
# =============================================================================

# Default environment
ENV ?= dev

# Colors for output
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
RESET := \033[0m

# Default target
.DEFAULT_GOAL := help

# =============================================================================
# PHONY TARGETS
# =============================================================================
.PHONY: help init plan apply destroy outputs clean tf-status ec2-status ec2-start ec2-stop ec2-connect ec2-ssh-key

# =============================================================================
# HELP
# =============================================================================

help: ## Show this help message
	@echo "$(BLUE)🚀 Terraform EC2 Development Server$(RESET)"
	@echo ""
	@echo "$(YELLOW)TERRAFORM COMMANDS:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## 🔧.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(RESET) %s\n", $$1, $$2}' | sed 's/🔧 //'
	@echo ""
	@echo "$(YELLOW)EC2 INSTANCE COMMANDS:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## 💻.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(RESET) %s\n", $$1, $$2}' | sed 's/💻 //'
	@echo ""
	@echo "$(BLUE)Quick Start:$(RESET)"
	@echo "  make apply           # Deploy infrastructure"
	@echo "  make ec2-ssh-key     # Save SSH key"
	@echo "  make ec2-connect     # Connect to server"
	@echo "  make destroy         # Clean up everything"

# =============================================================================
# TERRAFORM COMMANDS
# =============================================================================

init: ## 🔧 Initialize Terraform
	@echo "$(YELLOW)Initializing Terraform...$(RESET)"
	@terraform init

plan: ## 🔧 Show Terraform plan
	@echo "$(YELLOW)Planning deployment...$(RESET)"
	@if [ -f "environments/$(ENV)/terraform.tfvars" ]; then \
		terraform plan -var-file="environments/$(ENV)/terraform.tfvars"; \
	else \
		terraform plan; \
	fi

apply: ## 🔧 Apply Terraform configuration
	@echo "$(YELLOW)Applying Terraform configuration...$(RESET)"
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

tf-status: ## 🔧 Show Terraform state status
	@echo "$(YELLOW)Terraform State Status:$(RESET)"
	@if [ -f "terraform.tfstate" ]; then \
		echo "$(GREEN)✅ State file exists$(RESET)"; \
		echo "Resources: $$(terraform state list | wc -l)"; \
	else \
		echo "$(YELLOW)⚠️  No state file found$(RESET)"; \
	fi

clean: ## 🔧 Clean Terraform temporary files
	@echo "$(YELLOW)Cleaning Terraform files...$(RESET)"
	@rm -rf .terraform/
	@rm -f .terraform.lock.hcl
	@rm -f terraform.tfplan
	@rm -f terraform.tfstate.backup
	@echo "$(GREEN)✅ Cleaned temporary files$(RESET)"

# =============================================================================
# EC2 INSTANCE COMMANDS
# =============================================================================

ec2-ssh-key: ## 💻 Save SSH private key to ~/.ssh/
	@echo "$(YELLOW)Saving SSH private key...$(RESET)"
	@if terraform output private_key_pem > /dev/null 2>&1; then \
		terraform output -raw private_key_pem > ~/.ssh/data-ingestion-dev-key.pem; \
		chmod 600 ~/.ssh/data-ingestion-dev-key.pem; \
		echo "$(GREEN)✅ SSH key saved to ~/.ssh/data-ingestion-dev-key.pem$(RESET)"; \
	else \
		echo "$(RED)❌ No private key found. Deploy infrastructure first.$(RESET)"; \
	fi

ec2-connect: ## 💻 Connect to EC2 instance via SSH
	@echo "$(YELLOW)Connecting to EC2 instance...$(RESET)"
	@if terraform output instance_public_ip > /dev/null 2>&1; then \
		IP=$$(terraform output -raw instance_public_ip); \
		echo "$(GREEN)Connecting to: ubuntu@$$IP$(RESET)"; \
		ssh -i ~/.ssh/data-ingestion-dev-key.pem ubuntu@$$IP; \
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
		echo "$(YELLOW)💡 IP address may have changed after restart$(RESET)"; \
	else \
		echo "$(RED)❌ No instance found. Deploy infrastructure first.$(RESET)"; \
	fi