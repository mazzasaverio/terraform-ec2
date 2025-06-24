# 🔐 Secure Terraform EC2 Development Server

Modern, secure Terraform setup for a development server in AWS with **SSH keys stored safely outside Terraform state**.

## 🔒 Security Features

- **🔑 SSH Keys NOT in Terraform State** - Private keys remain local and secure
- **🛡️ External Key Generation** - Keys generated outside Terraform for maximum security
- **🔐 Automatic Security Checks** - Built-in validation to prevent key leaks
- **📝 Secure Outputs** - No sensitive data exposed in outputs

## 🎯 What You Get

- **🐚 Zsh + Oh My Zsh** - Enhanced shell with themes and plugins
- **🐳 Docker + Docker Compose** - Container platform ready to use
- **📦 Node.js + Python + AWS CLI** - Development tools pre-installed
- **🔐 Secure SSH Access** - Keys managed safely outside Terraform
- **🌐 Web Interface** - Simple status page to verify everything works

## ⚡ Quick Start (Secure)

```bash
# 1. Clone and setup
git clone <your-repo>
cd terraform-ec2/infrastructure
aws configure

# 2. Generate secure SSH keys
make ssh-keys

# 3. Configure your project
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Change project_name and owner

# 4. Deploy everything
make apply

# 5. Connect securely
make ec2-connect
```

## 🔐 Secure SSH Management

### **Step 1: Generate SSH Keys (SECURE)**
```bash
cd infrastructure
make ssh-keys
```

This creates:
- `../.ssh/terraform-ec2-key` (private key - stays local in root)
- `../.ssh/terraform-ec2-key.pub` (public key)
- `ssh_public_key.auto.tfvars` (Terraform variable file)

### **Step 2: Deploy Infrastructure**
```bash
make apply
```

### **Step 3: Connect Securely**
```bash
# Direct connection
make ec2-connect

# Or manual connection
ssh -i ../.ssh/terraform-ec2-key ubuntu@$(terraform output -raw instance_public_ip)
```

## 🔒 Security Validation

### **Check Security Status:**
```bash
make security-check
```

This validates:
- ✅ No private keys in Terraform state
- ✅ SSH key permissions (600)
- ✅ Proper key configuration

### **What's Protected:**
- **Private keys** never touch Terraform state
- **Keys directory** excluded from git
- **Auto-generated files** in .gitignore
- **Sensitive outputs** removed

## 📋 Available Commands

### **🔐 Security Commands:**
```bash
make ssh-keys        # Generate secure SSH keys
make check-keys      # Validate key configuration  
make security-check  # Comprehensive security audit
```

### **🔧 Terraform Commands:**
```bash
make help           # Show all commands
make init           # Initialize Terraform
make plan           # Show deployment plan
make apply          # Deploy infrastructure
make destroy        # Cleanup all resources
make outputs        # Show server information
```

### **💻 EC2 Commands:**
```bash
make ec2-connect    # SSH into instance (secure)
make ec2-status     # Show instance status
make ec2-start      # Start stopped instance
make ec2-stop       # Stop instance (save costs)
```

## 🛠️ What Gets Installed

### Shell & Tools
- Zsh with Oh My Zsh configuration
- Git, Vim, Curl, Wget, htop, tree, jq
- Build tools and development utilities

### Container Platform
- Docker CE (latest version)
- Docker Compose
- User added to docker group (no sudo needed)

### Development Environment
- Node.js LTS
- Python 3 + pip
- AWS CLI v2
- Nginx web server

## 🔧 Configuration

### Instance Types
- `t3a.large` (default) - 2 vCPUs, 8GB RAM
- `t3a.xlarge` - 4 vCPUs, 16GB RAM  
- `m5.large` - 2 vCPUs, 8GB RAM (Intel)

### Storage
- 30GB root volume (default, encrypted)
- gp3 SSD (latest generation)

### Network
- Public subnet with internet access
- Security group allows SSH (22), HTTP (80), HTTPS (443)
- Development ports 8000-8999 open for testing

## 🌍 Regions

Default: `eu-west-3` (Paris)

Supported regions:
- `eu-west-3` (Paris)
- `eu-west-1` (Ireland)
- `eu-central-1` (Frankfurt)
- `us-east-1` (N. Virginia)
- `us-west-2` (Oregon)

## 💰 Cost Estimation

- **t3a.large**: ~$50/month (if running 24/7)
- **Storage**: ~$3/month (30GB gp3)
- **Data transfer**: Minimal for development

> **Tip**: Use `make ec2-stop` when not coding to save money!

## 🔒 Security Best Practices

### **What We Do:**
- ✅ Private keys never in Terraform state
- ✅ Root volume encrypted by default
- ✅ Security groups configured for development
- ✅ SSH key-based authentication only
- ✅ Automatic security validation
- ✅ Git exclusions for sensitive files

### **What You Should Do:**
- 🔐 Keep private keys secure and local
- 🔄 Regularly rotate SSH keys
- 🛡️ Restrict security groups for production
- 📊 Monitor access logs
- 🧹 Clean up resources when done

## 🧹 Cleanup

```bash
# Destroy all resources when done
make destroy

# Security note: SSH keys remain safe locally
# Remove them manually if needed:
# rm -rf .ssh/
```

## 🚨 Troubleshooting

### **❌ "SSH keys not found"**
```bash
make ssh-keys
```

### **❌ "Permission denied (publickey)"**
```bash
make check-keys
chmod 600 .ssh/terraform-ec2-key
```

### **❌ "No instance found"**
```bash
make apply
```

### **❌ "SECURITY RISK: Private keys in state"**
This should never happen with the new system. If it does:
```bash
make security-check
# Contact support if this fails
```

## 📖 More Info

- **State management**: Local state files (perfect for development)
- **Modules**: Reusable VPC and EC2 modules
- **Tags**: Automatic tagging for cost tracking
- **Outputs**: Essential information (IP, SSH command, etc.)
- **Security**: SSH keys managed externally for maximum security

## 🎯 Perfect For

- Secure development and testing
- Learning Docker and cloud development
- Temporary development environments
- Code experiments that need more power than your laptop
- Security-conscious developers

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Test with `make apply`
4. Ensure `make security-check` passes
5. Submit a pull request

## 📝 License

MIT License - Use however you want! 🎉

---

**🔐 Remember: Your private keys are safe and never leave your machine!**