from sqlalchemy import create_engine
from sqlalchemy.exc import OperationalError
from app.core.config import settings
from sqlalchemy import text

  # adjust the import path to where your Settings class is

def test_db_connection():
    try:
        engine = create_engine(settings.DATABASE_URL)
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            print("Database connected successfully!", result.scalar())
    except OperationalError as e:
        print("Failed to connect to database:", e)

if __name__ == "__main__":
    test_db_connection()
