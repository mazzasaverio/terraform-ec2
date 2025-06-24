#!/usr/bin/env python3

import asyncio
import os
import sys
from pathlib import Path
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse

# Load .env file
def load_env():
    env_file = Path('.env')
    if env_file.exists():
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key] = value

# Load environment variables
load_env()

# Add src to path
sys.path.append('src')

async def test_neon_connection():
    """Test Neon database connection with detailed error reporting"""
    
    # Get the database URL from environment
    database_url = os.getenv('DATABASE_URL')
    if not database_url:
        print("❌ DATABASE_URL not set")
        print("Available environment variables:")
        for key, value in os.environ.items():
            if 'NEON' in key or 'DATABASE' in key:
                print(f"  {key}: {value[:50]}..." if len(value) > 50 else f"  {key}: {value}")
        return False
    
    print(f"🔗 Testing connection to: {database_url}")
    
    try:
        # Import SQLAlchemy components
        from sqlalchemy.ext.asyncio import create_async_engine
        from sqlalchemy import text
        
        # Convert to asyncpg format and handle SSL parameters
        if database_url.startswith("postgresql://") and not database_url.startswith("postgresql+asyncpg://"):
            # Parse the URL
            parsed = urlparse(database_url)
            query_params = parse_qs(parsed.query)
            
            # Remove sslmode from query parameters as it's handled differently by asyncpg
            if 'sslmode' in query_params:
                del query_params['sslmode']
            
            # Rebuild the URL without sslmode in query
            new_query = urlencode(query_params, doseq=True) if query_params else ""
            new_parsed = parsed._replace(
                scheme="postgresql+asyncpg",
                query=new_query
            )
            database_url = urlunparse(new_parsed)
            print(f"🔄 Converted URL to: {database_url}")
        
        # Create engine with SSL configuration
        print("🔧 Creating engine...")
        engine = create_async_engine(
            database_url,
            echo=True,  # Enable SQL logging
            pool_pre_ping=True,
            # SSL configuration for Neon
            connect_args={
                "ssl": "require" if "neon.tech" in database_url else False
            }
        )
        
        # Test connection
        print("🧪 Testing connection...")
        async with engine.begin() as conn:
            result = await conn.execute(text("SELECT 1 as test"))
            row = result.fetchone()
            print(f"✅ Connection successful! Test result: {row[0]}")
        
        await engine.dispose()
        return True
        
    except Exception as e:
        print(f"❌ Connection failed: {type(e).__name__}: {e}")
        return False

if __name__ == "__main__":
    success = asyncio.run(test_neon_connection())
    sys.exit(0 if success else 1) 