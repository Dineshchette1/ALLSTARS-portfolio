from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.core.config import settings

# Use declarative_base() from sqlalchemy.orm to avoid deprecation warning
DATABASE_URL = "postgresql+psycopg2://postgres:CHANGE_ME@localhost:5432/capstone_db"

engine = create_engine(DATABASE_URL)
Base = declarative_base()

# SQLALCHEMY_DATABASE_URL = settings.DATABASE_URL
#
# # Create the engine
# engine = create_engine(SQLALCHEMY_DATABASE_URL)

# Create a configured "Session" class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def create_all_tables():
    # Import all your models here so they are registered with Base.metadata
    from app.auth.models import User
   # from app.admin.models import Product  # example additional import
    # from app.orders.models import Order     # import all models that inherit from Base

    print("Creating tables...")
    Base.metadata.create_all(bind=engine)
    print("Tables created (if not existing already)")


if __name__ == "__main__":
    create_all_tables()
