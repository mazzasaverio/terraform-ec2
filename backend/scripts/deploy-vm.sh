#!/bin/bash

# Deployment script for EC2 virtual machine
set -e

echo "Deploying backend to virtual machine..."

# Check if running on Ubuntu/Debian
if ! command -v apt &> /dev/null; then
    echo "This script is designed for Ubuntu/Debian systems"
    exit 1
fi

# Update system
echo "Updating system packages..."
sudo apt update

# Install required packages
echo "Installing required packages..."
sudo apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib nginx

# Start and enable PostgreSQL
echo "Starting PostgreSQL service..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Setup PostgreSQL database
echo "Setting up PostgreSQL database..."
sudo -u postgres psql << EOF
CREATE DATABASE simple_backend;
CREATE USER postgres WITH PASSWORD 'postgres';
GRANT ALL PRIVILEGES ON DATABASE simple_backend TO postgres;
\q
EOF

# Create application directory
APP_DIR="/opt/simple-backend"
echo "Creating application directory: $APP_DIR"
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR

# Copy application files (assuming this script is run from the backend directory)
echo "Copying application files..."
cp -r . $APP_DIR/

# Setup Python environment
echo "Setting up Python environment..."
cd $APP_DIR
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

# Initialize database
echo "Initializing database..."
./scripts/init-db.sh

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/simple-backend.service > /dev/null << EOF
[Unit]
Description=Simple Backend API
After=network.target postgresql.service

[Service]
Type=exec
User=$USER
Group=$USER
WorkingDirectory=$APP_DIR
Environment=PATH=$APP_DIR/.venv/bin
ExecStart=$APP_DIR/.venv/bin/python -m uvicorn src.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
echo "Starting backend service..."
sudo systemctl daemon-reload
sudo systemctl enable simple-backend
sudo systemctl start simple-backend

# Configure firewall
echo "Configuring firewall..."
sudo ufw allow 8000
sudo ufw allow 80
sudo ufw allow 443

# Setup Nginx reverse proxy
echo "Setting up Nginx reverse proxy..."
sudo tee /etc/nginx/sites-available/simple-backend > /dev/null << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable Nginx site
sudo ln -sf /etc/nginx/sites-available/simple-backend /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

# Check services
echo "Checking services..."
sudo systemctl status postgresql --no-pager
sudo systemctl status simple-backend --no-pager
sudo systemctl status nginx --no-pager

echo "Deployment completed successfully!"
echo "Backend API is available at: http://$(curl -s ifconfig.me)"
echo "Sample user: admin / admin123"
echo ""
echo "Useful commands:"
echo "  View logs: sudo journalctl -u simple-backend -f"
echo "  Restart service: sudo systemctl restart simple-backend"
echo "  Check status: sudo systemctl status simple-backend" 