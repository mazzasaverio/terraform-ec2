# =============================================================================
# TERRAFORM EC2 + FASTAPI - UNIFIED SECURE MAKEFILE
# =============================================================================

# Colors for output
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
PURPLE := \033[35m
RESET := \033[0m

# SSH key paths (now in root directory)
SSH_KEY_DIR := .ssh
SSH_KEY_NAME := terraform-ec2-key
SSH_PRIVATE_KEY := $(SSH_KEY_DIR)/$(SSH_KEY_NAME)
SSH_PUBLIC_KEY := $(SSH_PRIVATE_KEY).pub

# Default target
.DEFAULT_GOAL := help

# =============================================================================
# PHONY TARGETS
# =============================================================================
.PHONY: help deploy-infra deploy-backend destroy status clean ssh logs test-local test-remote check-prerequisites

# =============================================================================
# HELP
# =============================================================================

help: ## Show this help message
	@echo "$(PURPLE)🔐 Terraform EC2 + FastAPI - Secure Full-Stack$(RESET)"
	@echo ""
	@echo "$(GREEN)🔒 SECURITY FEATURES:$(RESET)"
	@echo "  • SSH keys are NOT stored in Terraform state"
	@echo "  • Private keys remain local and secure"
	@echo "  • Keys are auto-generated outside Terraform"
	@echo ""
	@echo "$(YELLOW)🚀 MAIN DEPLOYMENT:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## 🚀.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' | sed 's/🚀 //'
	@echo ""
	@echo "$(YELLOW)🏗️  INFRASTRUCTURE:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## 🏗️.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' | sed 's/🏗️ //'
	@echo ""
	@echo "$(YELLOW)🐍 BACKEND:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## 🐍.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' | sed 's/🐍 //'
	@echo ""
	@echo "$(YELLOW)🧪 TESTING:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## 🧪.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' | sed 's/🧪 //'
	@echo ""
	@echo "$(YELLOW)🛠️  UTILITIES:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## 🛠️.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(RESET) %s\n", $$1, $$2}' | sed 's/🛠️ //'
	@echo ""
	@echo "$(BLUE)📋 Quick Start:$(RESET)"
	@echo "  $(GREEN)make status$(RESET)          # Show deployment status"
	@echo "  $(GREEN)make test-remote$(RESET)     # Test the deployed API"
	@echo "  $(GREEN)make destroy$(RESET)         # Clean up everything"

# =============================================================================
# PREREQUISITES CHECK
# =============================================================================

check-prerequisites: ## 🛠️ Check all prerequisites
	@echo "$(YELLOW)🔍 Checking prerequisites...$(RESET)"
	@if ! aws sts get-caller-identity >/dev/null 2>&1; then \
		echo "$(RED)❌ AWS CLI not configured. Run 'aws configure'$(RESET)"; \
		exit 1; \
	fi
	@if ! docker info >/dev/null 2>&1; then \
		echo "$(RED)❌ Docker is not running. Please start Docker Desktop$(RESET)"; \
		exit 1; \
	fi
	@if ! command -v terraform &> /dev/null; then \
		echo "$(RED)❌ Terraform not found. Please install Terraform$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ All prerequisites met$(RESET)"

# =============================================================================
# MAIN DEPLOYMENT COMMANDS
# =============================================================================

deploy-infra: check-prerequisites ## 🏗️ Deploy only infrastructure
	@echo "$(BLUE)🏗️ Deploying infrastructure with Terraform...$(RESET)"
	@if [ ! -f "infrastructure/terraform.tfvars" ]; then \
		echo "$(YELLOW)⚠️ terraform.tfvars not found. Creating from example...$(RESET)"; \
		cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars; \
		echo "$(RED)❌ Please edit infrastructure/terraform.tfvars with your values and run again$(RESET)"; \
		exit 1; \
	fi
	@cd infrastructure && make ssh-keys
	@cd infrastructure && make apply
	@echo "$(GREEN)✅ Infrastructure deployed successfully$(RESET)"

deploy-backend: ## 🐍 Deploy only backend (requires existing infrastructure)
	@echo "$(BLUE)🐍 Deploying FastAPI backend via ECR...$(RESET)"
	@if [ ! -f "backend/deploy-simple.sh" ]; then \
		echo "$(RED)❌ backend/deploy-simple.sh not found$(RESET)"; \
		exit 1; \
	fi
	@if [ ! -f "$(SSH_PRIVATE_KEY)" ]; then \
		echo "$(RED)❌ SSH key not found at $(SSH_PRIVATE_KEY)$(RESET)"; \
		echo "$(YELLOW)💡 Run: make infra-ssh-keys$(RESET)"; \
		exit 1; \
	fi
	@cd backend && ./deploy-simple.sh
	@echo "$(GREEN)✅ Backend deployed successfully via ECR$(RESET)"

destroy: ## 🚀 Destroy all infrastructure
	@echo "$(RED)💥 Destroying infrastructure...$(RESET)"
	@echo "$(YELLOW)⚠️  This will destroy all AWS resources!$(RESET)"
	@read -p "Are you sure? Type 'yes' to continue: " confirm && [ "$$confirm" = "yes" ]
	@cd infrastructure && make destroy
	@echo "$(GREEN)✅ Infrastructure destroyed$(RESET)"

# =============================================================================
# INFRASTRUCTURE COMMANDS
# =============================================================================

infra-init: ## 🏗️ Initialize Terraform
	@cd infrastructure && make init

infra-plan: ## 🏗️ Plan infrastructure changes
	@cd infrastructure && make plan

infra-apply: ## 🏗️ Apply infrastructure changes
	@cd infrastructure && make apply

infra-destroy: ## 🏗️ Destroy infrastructure
	@cd infrastructure && make destroy

infra-ssh-keys: ## 🏗️ Generate secure SSH keys
	@cd infrastructure && make ssh-keys

infra-security-check: ## 🏗️ Run security validation
	@cd infrastructure && make security-check

# =============================================================================
# BACKEND COMMANDS
# =============================================================================

backend-dev: ## 🐍 Start backend in development mode
	@echo "$(YELLOW)🔧 Starting backend in development mode...$(RESET)"
	@cd backend && docker compose up -d
	@echo "$(GREEN)✅ Backend running at http://localhost:8000$(RESET)"
	@echo "$(BLUE)📋 Docs: http://localhost:8000/docs$(RESET)"

backend-stop: ## 🐍 Stop local backend
	@echo "$(YELLOW)⏹️ Stopping local backend...$(RESET)"
	@cd backend && docker compose down

backend-build: ## 🐍 Build backend Docker image
	@echo "$(YELLOW)📦 Building backend image...$(RESET)"
	@cd backend && docker build -t simple-backend:latest .

backend-test: ## 🐍 Run backend tests
	@echo "$(YELLOW)🧪 Running backend tests...$(RESET)"
	@cd backend && uv run pytest tests/ -v || echo "$(YELLOW)⚠️ Tests not configured yet$(RESET)"

backend-logs: ## 🐍 Show local backend logs
	@cd backend && docker compose logs -f

# =============================================================================
# EC2 INSTANCE MANAGEMENT
# =============================================================================

ec2-start: ## 🛠️ Start stopped EC2 instance
	@cd infrastructure && make ec2-start

ec2-stop: ## 🛠️ Stop EC2 instance (save costs)
	@cd infrastructure && make ec2-stop

ec2-status: ## 🛠️ Check EC2 instance status
	@cd infrastructure && make ec2-status

ec2-connect: ## 🛠️ SSH into EC2 instance
	@cd infrastructure && make ec2-connect

# =============================================================================
# TESTING COMMANDS
# =============================================================================

test-local: ## 🧪 Test local backend endpoints
	@echo "$(YELLOW)🧪 Testing local backend...$(RESET)"
	@echo "$(BLUE)Root endpoint:$(RESET)"
	@curl -s http://localhost:8000/ | jq || echo "❌ Backend not running locally"
	@echo ""
	@echo "$(BLUE)Health check:$(RESET)"
	@curl -s http://localhost:8000/health | jq || echo "❌ Backend not responding"

test-remote: ## 🧪 Test remote backend on EC2
	@echo "$(YELLOW)🧪 Testing remote backend...$(RESET)"
	@EC2_IP=$$(cd infrastructure && terraform output -raw instance_public_ip 2>/dev/null || echo ""); \
	if [ -z "$$EC2_IP" ]; then \
		echo "$(RED)❌ No EC2 instance found$(RESET)"; \
		exit 1; \
	fi; \
	echo "$(BLUE)Testing http://$$EC2_IP:8000$(RESET)"; \
	echo "$(GREEN)Root endpoint:$(RESET)"; \
	curl -s http://$$EC2_IP:8000/ | jq || echo "❌ Backend not responding"; \
	echo ""; \
	echo "$(GREEN)Health check:$(RESET)"; \
	curl -s http://$$EC2_IP:8000/health | jq || echo "❌ Health check failed"; \
	echo ""; \
	echo "$(GREEN)Create message test:$(RESET)"; \
	curl -X POST http://$$EC2_IP:8000/messages \
		-H "Content-Type: application/json" \
		-d '{"content":"Test from Makefile"}' | jq || echo "❌ POST failed"

# =============================================================================
# UTILITY COMMANDS
# =============================================================================

status: ## 🛠️ Show deployment status
	@echo "$(PURPLE)📊 Deployment Status$(RESET)"
	@echo "$(BLUE)================================================================$(RESET)"
	@if [ -d "infrastructure" ]; then \
		cd infrastructure && \
		if terraform output instance_public_ip >/dev/null 2>&1; then \
			EC2_IP=$$(terraform output -raw instance_public_ip); \
			echo "$(GREEN)✅ Infrastructure: Deployed$(RESET)"; \
			echo "$(GREEN)🌐 EC2 Instance: $$EC2_IP$(RESET)"; \
			echo "$(GREEN)📋 API Docs: http://$$EC2_IP:8000/docs$(RESET)"; \
			echo "$(GREEN)🏥 Health Check: http://$$EC2_IP:8000/health$(RESET)"; \
			echo ""; \
			echo "$(YELLOW)🧪 Quick Test Commands:$(RESET)"; \
			echo "  curl http://$$EC2_IP:8000/"; \
			echo "  curl http://$$EC2_IP:8000/health"; \
			echo ""; \
			echo "$(YELLOW)🔗 SSH Access:$(RESET)"; \
			echo "  ssh -i .ssh/terraform-ec2-key ubuntu@$$EC2_IP"; \
			echo ""; \
			echo "$(YELLOW)📊 Monitor Container:$(RESET)"; \
			echo "  ssh -i .ssh/terraform-ec2-key ubuntu@$$EC2_IP 'docker logs simple-backend -f'"; \
		else \
			echo "$(RED)❌ Infrastructure: Not deployed$(RESET)"; \
		fi; \
	else \
		echo "$(RED)❌ Infrastructure directory not found$(RESET)"; \
	fi

ssh: ## 🛠️ SSH into EC2 instance
	@EC2_IP=$$(cd infrastructure && terraform output -raw instance_public_ip 2>/dev/null || echo ""); \
	if [ -z "$$EC2_IP" ]; then \
		echo "$(RED)❌ No EC2 instance found$(RESET)"; \
		exit 1; \
	fi; \
	if [ ! -f "$(SSH_PRIVATE_KEY)" ]; then \
		echo "$(RED)❌ SSH key not found. Run: make infra-ssh-keys$(RESET)"; \
		exit 1; \
	fi; \
	echo "$(YELLOW)🔗 Connecting to $$EC2_IP...$(RESET)"; \
	ssh -i $(SSH_PRIVATE_KEY) -o StrictHostKeyChecking=no ubuntu@$$EC2_IP

logs: ## 🛠️ Show backend container logs
	@EC2_IP=$$(cd infrastructure && terraform output -raw instance_public_ip 2>/dev/null || echo ""); \
	if [ -z "$$EC2_IP" ]; then \
		echo "$(RED)❌ No EC2 instance found$(RESET)"; \
		exit 1; \
	fi; \
	if [ ! -f "$(SSH_PRIVATE_KEY)" ]; then \
		echo "$(RED)❌ SSH key not found. Run: make infra-ssh-keys$(RESET)"; \
		exit 1; \
	fi; \
	echo "$(YELLOW)📊 Showing container logs...$(RESET)"; \
	ssh -i $(SSH_PRIVATE_KEY) -o StrictHostKeyChecking=no ubuntu@$$EC2_IP 'docker logs simple-backend -f'

clean: ## 🛠️ Clean up local Docker resources
	@echo "$(YELLOW)🧹 Cleaning up local resources...$(RESET)"
	@cd backend && docker compose down -v --remove-orphans || true
	@docker system prune -f
	@echo "$(GREEN)✅ Cleanup completed$(RESET)"

# =============================================================================
# DEVELOPMENT HELPERS
# =============================================================================

dev-setup: ## 🛠️ Set up development environment
	@echo "$(YELLOW)🔧 Setting up development environment...$(RESET)"
	@if [ ! -f "infrastructure/terraform.tfvars" ]; then \
		echo "$(YELLOW)📋 Creating terraform.tfvars from example...$(RESET)"; \
		cp infrastructure/terraform.tfvars.example infrastructure/terraform.tfvars; \
		echo "$(RED)❌ Please edit infrastructure/terraform.tfvars with your values$(RESET)"; \
	else \
		echo "$(GREEN)✅ terraform.tfvars already exists$(RESET)"; \
	fi
	@if [ ! -f "backend/.env" ]; then \
		echo "$(YELLOW)📋 Creating backend .env from example...$(RESET)"; \
		cp backend/.env.example backend/.env; \
		echo "$(GREEN)✅ Backend .env created$(RESET)"; \
	else \
		echo "$(GREEN)✅ Backend .env already exists$(RESET)"; \
	fi

open-docs: ## 🛠️ Open API documentation in browser
	@EC2_IP=$$(cd infrastructure && terraform output -raw instance_public_ip 2>/dev/null || echo ""); \
	if [ -z "$$EC2_IP" ]; then \
		echo "$(RED)❌ No EC2 instance found$(RESET)"; \
		exit 1; \
	fi; \
	echo "$(YELLOW)🌐 Opening http://$$EC2_IP:8000/docs$(RESET)"; \
	xdg-open http://$$EC2_IP:8000/docs 2>/dev/null || open http://$$EC2_IP:8000/docs 2>/dev/null || echo "$(YELLOW)💡 Open manually: http://$$EC2_IP:8000/docs$(RESET)"