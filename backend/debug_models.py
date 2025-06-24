import sys
sys.path.append('src')

from models.base import Base

print("Before importing models:")
print(f"Base.metadata.tables: {list(Base.metadata.tables.keys())}")

# Import models
from models.user import User
from models.message import Message
from models.feedback import Feedback
from models.post import Post
from models.like import Like
from models.bookmark import Bookmark
from models.url_bookmark import UrlBookmark

print("\nAfter importing models:")
print(f"Base.metadata.tables: {list(Base.metadata.tables.keys())}")

print("\nModel classes:")
print(f"User.__tablename__: {User.__tablename__}")
print(f"User.__table__ in Base.metadata.tables: {User.__table__ in Base.metadata.tables.values()}")

print(f"\nAll tables in metadata:")
for table_name, table in Base.metadata.tables.items():
    print(f"  - {table_name}: {table}") 