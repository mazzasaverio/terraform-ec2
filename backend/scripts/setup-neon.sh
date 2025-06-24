#!/bin/bash

# Setup script for Neon PostgreSQL
set -e

echo "Setting up Neon PostgreSQL database..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "Creating .env file from template..."
    cp env.example .env
    echo "Please edit .env file with your Neon database URL"
    exit 1
fi

# Load environment variables
set -a
source .env
set +a

# Function to convert to asyncpg URL
convert_to_asyncpg() {
    local url="$1"
    # Remove sslmode from query string
    url_no_sslmode=$(echo "$url" | sed 's/\([?&]\)sslmode=[^&]*//g' | sed 's/[?&]$//')
    # Convert scheme
    if [[ "$url_no_sslmode" == postgresql://* ]]; then
        echo "${url_no_sslmode/postgresql:\/\//postgresql+asyncpg://}"
    else
        echo "$url_no_sslmode"
    fi
}

# Function to remove +asyncpg for sync driver
convert_to_sync() {
    local url="$1"
    echo "$url" | sed 's|^postgresql+asyncpg://|postgresql://|'
}

# Convert URLs for Alembic (sync) and app/tests (async)
SYNC_URL=$(convert_to_sync "$DATABASE_URL")
ASYNC_URL=$(convert_to_asyncpg "$DATABASE_URL")

echo "Neon database URLs configured:"
echo "  Sync:  $SYNC_URL"
echo "  Async: $ASYNC_URL"

# Test database connection (async)
echo "Testing database connection (async)..."
DATABASE_URL="$ASYNC_URL" uv run python test_connection.py || { echo "✗ Database connection failed"; exit 1; }

# Run migrations (sync)
echo "Running migrations (sync)..."
DATABASE_URL="$SYNC_URL" uv run alembic upgrade head

sleep 2

# Create sample user (async)
echo "Creating sample user..."
DATABASE_URL="$ASYNC_URL" uv run python <<EOF
import asyncio
import sys
sys.path.append('src')
from utils.database import get_db_session
from repositories.user_repository import UserRepository

async def create_sample_user():
    async with get_db_session() as session:
        user_repo = UserRepository(session)
        try:
            user = await user_repo.create(
                user_id='admin-user-123',
                email='admin@example.com',
                avatar_url='https://example.com/avatar.jpg'
            )
            print(f'Created user: {user.userId}')
        except Exception as e:
            print(f'User might already exist: {e}')

asyncio.run(create_sample_user())
EOF

echo "Neon PostgreSQL setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Test development: docker-compose up --build"
echo "2. Test production: docker-compose -f docker-compose.prod.yml up --build"
echo "3. Run tests: ./scripts/test-docker.sh" 