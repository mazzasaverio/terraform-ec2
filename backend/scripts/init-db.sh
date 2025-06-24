#!/bin/bash

# Initialize database with migrations and sample data
set -e

echo "Initializing database..."

# Change to backend directory
cd "$(dirname "$0")/.."

# Install dependencies if not already installed
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -e .

# Initialize Alembic if not already done
if [ ! -d "alembic/versions" ]; then
    echo "Initializing Alembic..."
    alembic init alembic
fi

# Create initial migration
echo "Creating initial migration..."
alembic revision --autogenerate -m "Initial migration"

# Run migrations
echo "Running migrations..."
alembic upgrade head

# Create sample user
echo "Creating sample user..."
python -c "
import asyncio
import sys
import os
sys.path.append('src')

from utils.database import get_db_session
from repositories.user_repository import UserRepository

async def create_sample_user():
    async with get_db_session() as session:
        user_repo = UserRepository(session)
        try:
            user = await user_repo.create(
                username='admin',
                password='admin123',
                email='admin@example.com',
                role='admin'
            )
            print(f'Created user: {user.username}')
        except Exception as e:
            print(f'User might already exist: {e}')

asyncio.run(create_sample_user())
"

echo "Database initialization completed!"
echo "Sample user created:"
echo "  Username: admin"
echo "  Password: admin123" 