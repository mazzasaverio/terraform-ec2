# 🚀 Terraform EC2 Development Server

Simple Terraform setup for a development server in AWS with all the tools you need for coding.

## 🎯 What You Get

- **🐚 Zsh + Oh My Zsh** - Enhanced shell with themes and plugins
- **🐳 Docker + Docker Compose** - Container platform ready to use
- **📦 Node.js + Python + AWS CLI** - Development tools pre-installed
- **🔐 SSH Key** - Automatically generated and configured
- **🌐 Web Interface** - Simple status page to verify everything works

## ⚡ Quick Start

```bash
# 1. Clone and setup
git clone <your-repo>
cd terraform-ec2
aws configure

# 2. Configure your project
cp terraform.tfvars.example environments/dev/terraform.tfvars
nano environments/dev/terraform.tfvars  # Change project_name and owner

# 3. Deploy everything
make apply

# 4. Save SSH key and connect
terraform output -raw private_key_pem > ~/.ssh/data-ingestion-dev-key.pem
chmod 600 ~/.ssh/data-ingestion-dev-key.pem
ssh -i ~/.ssh/data-ingestion-dev-key.pem ubuntu@$(terraform output -raw instance_public_ip)
```

## 🔐 SSH Connection

### After deploying with `make apply`:

**1. Save the SSH private key:**
```bash
# Save to ~/.ssh directory
terraform output -raw private_key_pem > ~/.ssh/data-ingestion-dev-key.pem
chmod 600 ~/.ssh/data-ingestion-dev-key.pem
```

**2. Get the server IP:**
```bash
terraform output instance_public_ip
```

**3. Connect via SSH:**
```bash
# Direct connection
ssh -i ~/.ssh/data-ingestion-dev-key.pem ubuntu@$(terraform output -raw instance_public_ip)

# Or save IP first
IP=$(terraform output -raw instance_public_ip)
ssh -i ~/.ssh/data-ingestion-dev-key.pem ubuntu@$IP
```

### Optional: Configure SSH for easier access

**Add to ~/.ssh/config:**
```bash
# Get the IP and add SSH config entry
IP=$(terraform output -raw instance_public_ip)
cat >> ~/.ssh/config << EOF
Host data-ingestion-dev
    HostName $IP
    User ubuntu
    IdentityFile ~/.ssh/data-ingestion-dev-key.pem
EOF

# Then connect simply with:
ssh data-ingestion-dev
```

**Or use SSH agent:**
```bash
# Add key to SSH agent
ssh-add ~/.ssh/data-ingestion-dev-key.pem

# Connect without specifying key file
ssh ubuntu@$(terraform output -raw instance_public_ip)
```

### Users Available
- **ubuntu** - Default user with sudo access
- **dev** - Custom development user with sudo access (configurable)

Both users have Zsh + Oh My Zsh pre-configured.

## 📋 Available Commands

```bash
make help          # Show all commands
make init          # Initialize Terraform
make plan          # Show deployment plan
make apply         # Deploy infrastructure
make destroy       # Cleanup all resources
make outputs       # Show server information
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

> **Tip**: Use `make destroy` when not coding to save money!

## 🔒 Security

- Root volume encrypted by default
- Security groups configured for development use
- SSH key automatically generated (4096-bit RSA)
- No passwords - key-based authentication only
- Private key stored in Terraform state (sensitive)

## 🧹 Cleanup

```bash
# Destroy all resources when done
make destroy

# Remove SSH key (optional)
rm ~/.ssh/data-ingestion-dev-key.pem
```

## 📖 More Info

- **State management**: Local state files (perfect for development)
- **Modules**: Reusable VPC and EC2 modules
- **Tags**: Automatic tagging for cost tracking
- **Outputs**: Essential information (IP, SSH command, private key)

## 🎯 Perfect For

- Development and testing
- Learning Docker and cloud development
- Temporary development environments
- Code experiments that need more power than your laptop

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Test with `make apply`
4. Submit a pull request

## 📝 License

MIT License - Use however you want!