import pytest
from fastapi.testclient import TestClient
from app.main import app  # Your FastAPI app instance
from app.database import Base, engine, SessionLocal

# Create the tables for testing
Base.metadata.create_all(bind=engine)

@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c

@pytest.fixture(scope="function")
def db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
