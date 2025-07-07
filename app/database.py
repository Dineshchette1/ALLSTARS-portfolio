from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.core.config import settings
import os
from dotenv import load_dotenv
import time
import sqlalchemy.exc

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
# DATABASE_URL example: "postgresql+psycopg2://postgres:CHANGE_ME@localhost:5432/capstone_db"

engine = create_engine(DATABASE_URL)
Base = declarative_base()

MAX_RETRIES = 10
RETRY_DELAY = 3  # seconds

for i in range(MAX_RETRIES):
    try:
        engine.connect()
        print("Database connected!")
        break
    except sqlalchemy.exc.OperationalError:
        print(f"DB not ready, retrying in {RETRY_DELAY} seconds... ({i + 1}/{MAX_RETRIES})")
        time.sleep(RETRY_DELAY)
else:
    print("Could not connect to DB after retries. Exiting.")
    exit(1)

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
    from app.cart.models import CartItem  # example additional import
    # from app.orders.models import Order     # import all models that inherit from Base

    print("Creating tables...")
    Base.metadata.create_all(bind=engine)
    print("Tables created (if not existing already)")


if __name__ == "__main__":
    create_all_tables()
