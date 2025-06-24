#!/bin/bash

# Test script using Docker Compose with Neon PostgreSQL
set -e

echo "Running tests with Docker Compose and Neon PostgreSQL..."

# Check if environment variables are set
if [ -z "$NEON_DEV_DATABASE_URL" ]; then
    echo "Error: NEON_DEV_DATABASE_URL environment variable is not set"
    echo "Please set it in your .env file or export it"
    exit 1
fi

# Run tests
echo "Running tests..."
docker-compose run --rm backend python -m pytest tests/ -v

echo "Tests completed!" 