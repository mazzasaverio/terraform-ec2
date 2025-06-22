#!/bin/bash

# =============================================================================
# MINIMAL DEV SERVER SETUP - ESSENTIALS ONLY
# =============================================================================

set -e

# Variables from Terraform
PROJECT_NAME="${project_name}"
DEV_USERNAME="${username}"

# Logging
LOG_FILE="/var/log/user-data-setup.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "=== Setting up development server for $PROJECT_NAME ==="
echo "=== $(date) ==="

# =============================================================================
# SYSTEM UPDATES
# =============================================================================

echo "=== Updating system ==="
apt-get update -y
apt-get upgrade -y

# =============================================================================
# ESSENTIAL TOOLS
# =============================================================================

echo "=== Installing essential tools ==="

apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    tree \
    unzip \
    jq \
    build-essential \
    zsh \
    fonts-powerline

# =============================================================================
# DOCKER INSTALLATION
# =============================================================================

echo "=== Installing Docker ==="

# Add Docker GPG key and repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker and add users to docker group
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

echo "=== Docker installed ==="

# =============================================================================
# USER SETUP
# =============================================================================

echo "=== Creating development user: $DEV_USERNAME ==="

if ! id "$DEV_USERNAME" &>/dev/null; then
    useradd -m -s /bin/zsh -G sudo,docker "$DEV_USERNAME"
    echo "$DEV_USERNAME:$(openssl rand -base64 32)" | chpasswd
    echo "$DEV_USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$DEV_USERNAME
    echo "=== User $DEV_USERNAME created ==="
fi

# =============================================================================
# ZSH + OH MY ZSH SETUP
# =============================================================================

echo "=== Setting up Zsh + Oh My Zsh ==="

# Change shell for ubuntu user
chsh -s /bin/zsh ubuntu

# Install Oh My Zsh for ubuntu
sudo -u ubuntu sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Simple .zshrc for ubuntu
sudo -u ubuntu cat > /home/ubuntu/.zshrc << 'EOF'
# Oh My Zsh config
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Basic plugins
plugins=(git docker)

source $ZSH/oh-my-zsh.sh

# Basic aliases
alias ll='ls -la'
alias d='docker'
alias dc='docker compose'

# Welcome
echo "🚀 Development server ready!"
EOF

# Same setup for dev user
sudo -u "$DEV_USERNAME" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
cp /home/ubuntu/.zshrc "/home/$DEV_USERNAME/.zshrc"
chown "$DEV_USERNAME:$DEV_USERNAME" "/home/$DEV_USERNAME/.zshrc"

# =============================================================================
# DEVELOPMENT TOOLS
# =============================================================================

echo "=== Installing development tools ==="

# Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs

# Python tools
apt-get install -y python3-pip

# AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# =============================================================================
# PROJECT DIRECTORIES
# =============================================================================

echo "=== Creating project directories ==="

# Create directories
mkdir -p /home/ubuntu/projects
mkdir -p "/home/$DEV_USERNAME/projects"

# Set ownership
chown -R ubuntu:ubuntu /home/ubuntu/
chown -R "$DEV_USERNAME:$DEV_USERNAME" "/home/$DEV_USERNAME/"

# =============================================================================
# FINALIZATION
# =============================================================================

echo "=== Setup complete ==="

# Simple welcome message
cat > /etc/motd << EOF

🚀 $PROJECT_NAME Development Server

📋 Ready to use:
   • Zsh + Oh My Zsh
   • Docker + Docker Compose  
   • Node.js + Python + AWS CLI
   • Git and development tools

👤 Users: ubuntu, $DEV_USERNAME
📁 Projects: ~/projects/

Happy coding! 🎉

EOF

# Cleanup
apt-get autoremove -y
apt-get autoclean

echo "=== Development server ready! ==="
echo "=== $(date) ==="