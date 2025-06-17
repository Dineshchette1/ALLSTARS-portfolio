# tests/test_cart.py
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.cart.routers import router as cart_router
from app.database import Base
from fastapi import FastAPI, Depends
from app.cart.models import CartItem
from app.auth.models import User
from app.admin.models import Product
from app.cart.routers import get_db

# Create a temporary SQLite in-memory database for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"  # or "sqlite:///:memory:" if no threading issues
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create test app and include router
app = FastAPI()
app.include_router(cart_router, prefix="/cart")

# Override the get_db dependency
def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides = {}
app.dependency_overrides[get_db] = override_get_db

# Set up the database once before tests
@pytest.fixture(scope="module", autouse=True)
def setup_database():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    user = User(id=1)
    product = Product(id=101)
    db.add_all([user, product])
    db.commit()
    db.close()
    yield
    Base.metadata.drop_all(bind=engine)

client = TestClient(app)

# Test add_to_cart
def test_add_to_cart():
    response = client.post("/cart/add", params={"user_id": 1, "product_id": 101, "quantity": 2})
    assert response.status_code == 200
    assert response.json() == {"message": "Item added to cart"}

# Test get_cart_items
def test_get_cart_items():
    response = client.get("/cart/items", params={"user_id": 1})
    assert response.status_code == 200
    assert response.json() == {"cart": [{"product_id": 101, "quantity": 2}]}

# Test update_cart_item
def test_update_cart_item():
    response = client.put("/cart/update", params={"user_id": 1, "product_id": 101, "quantity": 5})
    assert response.status_code == 200
    assert response.json() == {"message": "Cart item updated"}

# Test remove_cart_item
def test_remove_cart_item():
    response = client.delete("/cart/remove", params={"user_id": 1, "product_id": 101})
    assert response.status_code == 200
    assert response.json() == {"message": "Item removed from cart"}

# Test clear_cart when already empty
def test_clear_empty_cart():
    response = client.delete("/cart/clear", params={"user_id": 1})
    assert response.status_code == 200
    assert response.json() == {"message": "Cart already empty"}
