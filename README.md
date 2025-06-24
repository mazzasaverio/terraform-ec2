# 🔐 Terraform EC2 + FastAPI - Secure Full-Stack Deployment

Modern, secure full-stack setup with **Terraform infrastructure** + **FastAPI backend** deployed on AWS EC2 with **SSH keys stored safely outside Terraform state** and **S3 storage integration**.

## 🔒 Security Features

- **🔑 SSH Keys NOT in Terraform State** - Private keys remain local and secure
- **🛡️ External Key Generation** - Keys generated outside Terraform for maximum security
- **🔐 Automatic Security Checks** - Built-in validation to prevent key leaks
- **📝 Secure Outputs** - No sensitive data exposed in outputs
- **🐳 Containerized Backend** - FastAPI runs in Docker with health checks
- **🗄️ S3 Storage Integration** - Secure cloud storage with IAM roles

## 🎯 What You Get

### **Infrastructure (Terraform)**
- **🌐 VPC with Public Subnets** - Secure network setup
- **💻 EC2 Instance (t3a.large)** - Development server with Docker pre-installed
- **🔐 Security Groups** - Configured for SSH, HTTP, HTTPS, and development ports
- **🗄️ Encrypted Storage** - 30GB gp3 SSD with encryption
- **📦 S3 Buckets** - Application data and logs storage with lifecycle policies
- **🔑 IAM Roles** - Secure access to S3 and ECR services

### **Backend (FastAPI)**
- **🚀 FastAPI Application** - Modern Python API with automatic docs
- **🐳 Docker Containerization** - Consistent deployment environment
- **📝 Loguru Logging** - File + console logging with rotation
- **🔄 Auto-restart** - Container restarts automatically
- **🏥 Health Checks** - Built-in monitoring endpoints
- **📦 S3 Integration** - File upload/download and storage management

## ⚡ Quick Start (Complete Deployment)

### **🔧 Step-by-Step Deployment**
```bash
# 1. Clone and setup
git clone <your-repo>
cd terraform-ec2
aws configure

# 2. Setup infrastructure
cd infrastructure
make ssh-keys      # Generate secure SSH keys
make apply         # Deploy AWS infrastructure (includes S3)

# 3. Setup S3 storage
cd ..
./scripts/setup-s3.sh  # Configure S3 access and sync scripts

# 4. Deploy backend via ECR
cd backend
./deploy-simple.sh # Deploy FastAPI to EC2 via ECR

# 5. Verify deployment
cd ..
make status        # Check everything is running
```

## 📦 S3 Storage Setup

### **Quick S3 Setup**
```bash
# Run the S3 setup script
./scripts/setup-s3.sh

# This will:
# ✅ Test S3 connectivity
# ✅ Create directory structure
# ✅ Generate sync scripts
# ✅ Create configuration files
```

### **S3 Bucket Structure**
```
s3://your-project-dev-app-data-xxxxxxxx/
├── data/
│   ├── input/          # Input files
│   ├── output/         # Processed results
│   ├── temp/           # Temporary files
│   └── logs/           # Application logs
```

### **Local S3 Operations**
```bash
# Sync local data to S3
./sync-s3.sh up

# Sync S3 data to local
./sync-s3.sh down

# Sync logs to S3
./sync-s3.sh logs
```

### **EC2 S3 Operations**
```bash
# SSH to EC2
ssh -i .ssh/terraform-ec2-key ubuntu@$(terraform output -raw instance_public_ip)

# Test S3 access
s3-test

# Sync data
s3-sync up
s3-sync down
s3-sync logs
```

### **FastAPI S3 Endpoints**
```bash
# Get authentication token
curl -X POST "http://YOUR_IP:8000/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"

# List S3 files
curl -X GET "http://YOUR_IP:8000/s3/files?data_type=input" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Upload file
curl -X POST "http://YOUR_IP:8000/s3/upload" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@local-file.txt" \
  -F "data_type=input"
```

**📖 For detailed S3 setup instructions, see [S3_SETUP.md](S3_SETUP.md)**

## 🔐 Secure SSH Management

### **Step 1: Generate SSH Keys (SECURE)**
```bash
cd infrastructure
make ssh-keys
```

**Creates:**
- `.ssh/terraform-ec2-key` (private key - stays local in root)
- `.ssh/terraform-ec2-key.pub` (public key)
- `ssh_public_key.auto.tfvars` (Terraform variable file)

### **Step 2: Deploy Infrastructure**
```bash
cd infrastructure
make apply
```

### **Step 3: Setup S3 Storage**
```bash
cd ..
./scripts/setup-s3.sh
```

### **Step 4: Deploy FastAPI Backend**
```bash
cd backend
./deploy-simple.sh
```

### **Step 5: Access Your Application**
```bash
# Get your instance IP
cd infrastructure
IP=$(terraform output -raw instance_public_ip)

# Test API endpoints
curl http://$IP:8000/                    # Welcome message
curl http://$IP:8000/health              # Health check
curl http://$IP:8000/docs                # Interactive docs (browser)
```

## 🔒 Security Validation

### **Check Security Status:**
```bash
cd infrastructure
make security-check
```

**Validates:**
- ✅ No private keys in Terraform state
- ✅ SSH key permissions (600)
- ✅ Proper key configuration

## 📋 Available Commands

### **🚀 Main Deployment Commands:**
```bash
make deploy-backend  # Deploy backend via ECR
make status          # Show deployment status and URLs
make destroy         # Destroy everything (cleanup)
make clean           # Clean local Docker resources
```

### **🔐 Security Commands:**
```bash
cd infrastructure/
make ssh-keys        # Generate secure SSH keys
make check-keys      # Validate key configuration  
make security-check  # Comprehensive security audit
```

### **🔧 Infrastructure Commands:**
```bash
cd infrastructure/
make help           # Show all infrastructure commands
make init           # Initialize Terraform
make plan           # Show deployment plan
make apply          # Deploy infrastructure
make destroy        # Cleanup AWS resources
make outputs        # Show server information
```

### **💻 EC2 Instance Management:**
```bash
cd infrastructure/
make ec2-connect    # SSH into instance (secure)
make ec2-status     # Show instance status
make ec2-start      # Start stopped instance
make ec2-stop       # Stop instance (save costs)
```

### **🐳 Backend Commands:**
```bash
cd backend/
make dev            # Run locally for development
make build          # Build Docker image
make test           # Run tests
./deploy-simple.sh  # Deploy to EC2 via ECR
```

### **📦 S3 Storage Commands:**
```bash
./scripts/setup-s3.sh  # Setup S3 access and scripts
./sync-s3.sh up        # Sync local data to S3
./sync-s3.sh down      # Sync S3 data to local
./sync-s3.sh logs      # Sync logs to S3
```

### **🛠️ Utility Commands:**
```bash
make ssh            # SSH into EC2 instance
make logs           # Show backend container logs
make test-local     # Test backend locally
make test-remote    # Test deployed backend
```

## 🧪 Testing Your Deployment

### **1. 🏥 Health Checks**
```bash
# Get instance IP
IP=$(cd infrastructure && terraform output -raw instance_public_ip)

# Test all endpoints
curl http://$IP:8000/                    # Welcome message
curl http://$IP:8000/health              # Health status
curl -X GET http://$IP:8000/messages     # Get messages
curl -X POST http://$IP:8000/messages \
  -H "Content-Type: application/json" \
  -d '{"content": "Hello World!"}'       # Create message
```

### **2. 📦 S3 Storage Tests**
```bash
# Test S3 connectivity
curl -X GET "http://$IP:8000/s3/health" \
  -H "Authorization: Bearer YOUR_TOKEN"

# List S3 files
curl -X GET "http://$IP:8000/s3/files?data_type=input" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Upload test file
echo "test content" > test.txt
curl -X POST "http://$IP:8000/s3/upload" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@test.txt" \
  -F "data_type=input"
```

### **3. 📋 Interactive Documentation**
Open in browser:
- **Swagger UI:** http://YOUR_IP:8000/docs
- **ReDoc:** http://YOUR_IP:8000/redoc

### **4. 📊 Monitoring**
```bash
# Container status
make ssh
docker ps
docker logs simple-backend

# System resources
htop
df -h

# S3 access from EC2
s3-test
```

## 💾 VM Management (Start/Stop to Save Costs)

### **💰 Stop Instance (Save Money)**
```bash
cd infrastructure
make ec2-stop
```
**Benefits:**
- ✅ Stops billing for compute time
- ✅ Keeps storage (small cost)
- ✅ Preserves all data and configuration
- ✅ Can restart anytime

### **🚀 Start Instance (Resume Work)**
```bash
cd infrastructure
make ec2-start
```
**What happens:**
- ✅ Instance starts with new public IP
- ✅ All data and containers preserved
- ✅ Backend auto-restarts
- ⚠️ **Note:** Public IP changes on restart

### **🔄 Complete Restart Workflow**
```bash
# Stop when done working
make ec2-stop

# Later, when you want to work again
make ec2-start

# Get new IP and test
IP=$(terraform output -raw instance_public_ip)
curl http://$IP:8000/health

# If backend needs restart
make ssh
docker restart simple-backend
```

### **📊 Check Instance Status**
```bash
cd infrastructure
make ec2-status
```

**Shows:**
- Instance state (running/stopped)
- Current public IP
- SSH connection command

## 🔧 Configuration

### **Infrastructure (infrastructure/terraform.tfvars):**
```hcl
project_name = "my-fastapi-project"
environment  = "dev"
owner        = "your-name"
aws_region   = "eu-west-3"
instance_type = "t3a.large"    # 2 vCPUs, 8GB RAM
```

### **Backend (backend/.env):**
```bash
ENVIRONMENT=production
LOG_LEVEL=INFO
API_HOST=0.0.0.0
API_PORT=8000
SECRET_KEY=your-secret-key
```

## 💰 Cost Management

### **💵 Typical Costs (EU-West-3):**
- **Running 24/7:** ~$50/month
- **Storage only:** ~$3/month
- **8 hours/day:** ~$15/month

### **💡 Cost-Saving Tips:**
```bash
# Stop when not using (saves ~90% costs)
make ec2-stop

# Check status before starting work
make ec2-status

# Start only when needed
make ec2-start

# Completely destroy when project is done
make destroy
```

## 🚨 Troubleshooting

### **❌ "SSH keys not found"**
```bash
cd infrastructure
make ssh-keys
```

### **❌ "Permission denied (publickey)"**
```bash
cd infrastructure
make check-keys
chmod 600 .ssh/terraform-ec2-key
```

### **❌ "Backend not responding"**
```bash
# Check container status
make ssh
docker ps
docker restart simple-backend

# Check logs
docker logs simple-backend -f
```

### **❌ "Instance stopped/IP changed"**
```bash
cd infrastructure
make ec2-start
IP=$(terraform output -raw instance_public_ip)
echo "New IP: $IP"
```

### **❌ "Port 8000 not accessible"**
```bash
# Check security group
cd infrastructure
terraform output security_group_id

# Restart backend container
make ssh
docker restart simple-backend
```

## 🔄 Daily Workflow

### **🌅 Starting Work:**
```bash
# 1. Start instance if stopped
cd infrastructure && make ec2-start

# 2. Get current IP
IP=$(terraform output -raw instance_public_ip)

# 3. Test backend
curl http://$IP:8000/health

# 4. Start coding!
```

### **🌙 Ending Work:**
```bash
# 1. Commit your changes
git add . && git commit -m "Daily progress"

# 2. Stop instance to save money
cd infrastructure && make ec2-stop

# 3. Confirm it's stopped
make ec2-status
```

### **🔄 Updating Backend:**
```bash
# 1. Make changes to backend code
# 2. Deploy updates
cd backend && ./deploy.sh

# 3. Test changes
curl http://$(cd ../infrastructure && terraform output -raw instance_public_ip):8000/
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Developer     │    │   AWS Cloud      │    │   EC2 Instance  │
│                 │    │                  │    │                 │
│ • Terraform     │───▶│ • VPC            │───▶│ • Ubuntu Server │
│ • SSH Keys      │    │ • Security Group │    │ • Docker        │
│ • Local Dev     │    │ • Public Subnet  │    │ • FastAPI       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🛡️ Security Best Practices

### **What We Do:**
- ✅ Private keys never in Terraform state
- ✅ Root volume encrypted by default
- ✅ Security groups configured properly
- ✅ SSH key-based authentication only
- ✅ Automatic security validation
- ✅ Git exclusions for sensitive files
- ✅ Container security with health checks

### **What You Should Do:**
- 🔐 Keep private keys secure and local
- 🔄 Regularly rotate SSH keys
- 🛡️ Restrict security groups for production
- 📊 Monitor access logs
- 🧹 Stop instances when not in use
- 💾 Backup important data

## 🧹 Cleanup

### **🛑 Stop Instance (Temporary)**
```bash
cd infrastructure
make ec2-stop  # Keeps everything, just stops billing
```

### **🗑️ Destroy Everything (Permanent)**
```bash
# WARNING: This deletes everything!
make destroy

# Confirm cleanup
cd infrastructure
terraform state list  # Should be empty
```

### **🧹 Clean Local Resources**
```bash
make clean

# Remove SSH keys if desired
rm -rf infrastructure/.ssh/
```

## 📚 Next Steps

### **🚀 Enhancements:**
- ✅ Add database integration (PostgreSQL/RDS)
- ✅ Implement CI/CD with GitHub Actions  
- ✅ Add SSL/TLS with Let's Encrypt
- ✅ Configure load balancer for scaling
- ✅ Add monitoring with CloudWatch
- ✅ Implement backup strategies

### **🎓 Learning Resources:**
- **FastAPI:** https://fastapi.tiangolo.com/
- **Terraform:** https://learn.hashicorp.com/terraform
- **Docker:** https://docs.docker.com/get-started/
- **AWS:** https://aws.amazon.com/getting-started/

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Test locally: `make test-local`
4. Test deployment: `make deploy`
5. Ensure security: `cd infrastructure && make security-check`
6. Commit changes: `git commit -m 'Add amazing feature'`
7. Push to branch: `git push origin feature/amazing-feature`
8. Submit Pull Request

## 📝 License

MIT License - Feel free to use this however you want! 🎉

---

## 🎯 Quick Reference

### **🚀 Deploy Everything:**
```bash
make deploy
```

### **💰 Save Money:**
```bash
cd infrastructure && make ec2-stop
```

### **🔄 Resume Work:**
```bash
cd infrastructure && make ec2-start
```

### **🔐 Stay Secure:**
```bash
cd infrastructure && make security-check
```

**🔐 Remember: Your private keys are safe and never leave your machine!** 