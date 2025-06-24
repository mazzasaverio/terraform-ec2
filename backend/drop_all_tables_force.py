import os
from sqlalchemy import create_engine, text

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL not set")

if DATABASE_URL.startswith("postgresql+asyncpg://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")

engine = create_engine(DATABASE_URL)

with engine.connect() as conn:
    # Drop all tables with CASCADE
    conn.execute(text("""
        DO $$ DECLARE 
            r RECORD;
        BEGIN
            FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = current_schema()) 
            LOOP
                EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
            END LOOP;
        END $$;
    """))
    
    # Also drop any remaining sequences
    conn.execute(text("""
        DO $$ DECLARE 
            r RECORD;
        BEGIN
            FOR r IN (SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = current_schema()) 
            LOOP
                EXECUTE 'DROP SEQUENCE IF EXISTS ' || quote_ident(r.sequence_name) || ' CASCADE';
            END LOOP;
        END $$;
    """))
    
    print("All tables and sequences dropped with CASCADE.") 