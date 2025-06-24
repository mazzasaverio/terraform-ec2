#!/bin/bash

# Setup script for local PostgreSQL database
set -e

echo "Setting up local PostgreSQL database..."

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "PostgreSQL is not installed. Please install PostgreSQL first."
    echo "On Ubuntu/Debian: sudo apt-get install postgresql postgresql-contrib"
    echo "On macOS: brew install postgresql"
    exit 1
fi

# Check if PostgreSQL service is running
if ! pg_isready -q; then
    echo "PostgreSQL service is not running. Starting it..."
    if command -v systemctl &> /dev/null; then
        sudo systemctl start postgresql
    elif command -v brew &> /dev/null; then
        brew services start postgresql
    else
        echo "Please start PostgreSQL service manually"
        exit 1
    fi
fi

# Create database and user
echo "Creating database and user..."
sudo -u postgres psql << EOF
CREATE DATABASE simple_backend;
CREATE USER postgres WITH PASSWORD 'postgres';
GRANT ALL PRIVILEGES ON DATABASE simple_backend TO postgres;
\q
EOF

echo "Database setup completed successfully!"
echo "You can now run the application with:"
echo "cd backend && python -m uvicorn src.main:app --reload" 