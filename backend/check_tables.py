import os
from sqlalchemy import create_engine, text, inspect

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL not set")

if DATABASE_URL.startswith("postgresql+asyncpg://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")

engine = create_engine(DATABASE_URL)

with engine.connect() as conn:
    inspector = inspect(conn)
    tables = inspector.get_table_names()
    print("Tables in database:")
    for table in tables:
        print(f"  - {table}")
    
    # Also check for indexes
    print("\nIndexes in database:")
    for table_name in tables:
        indexes = inspector.get_indexes(table_name)
        for index in indexes:
            print(f"  - {table_name}.{index['name']}") 