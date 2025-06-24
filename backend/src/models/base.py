from sqlalchemy.ext.declarative import declarative_base

# Base class for SQLAlchemy models - separate from database.py to avoid circular imports
Base = declarative_base() 