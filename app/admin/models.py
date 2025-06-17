from sqlalchemy import Column, Integer, String, ForeignKey, Float
from sqlalchemy.orm import relationship
from sqlalchemy import create_engine
from app.database import Base  # import Base from database.py
from sqlalchemy.orm import declarative_base
import random

DATABASE_URL = "postgresql+psycopg2://postgres:CHANGE_ME@localhost:5432/capstone_db"

engine = create_engine(DATABASE_URL)
#Base = declarative_base()

from sqlalchemy import BigInteger

def generate_16_digit_id():
    return random.randint(10**15, 10**16 - 1)

class Category(Base):
    __tablename__ = "categories"

    id = Column(BigInteger, primary_key=True, index=True, default=generate_16_digit_id, unique=True)
    name = Column(String, unique=True, index=True, nullable=False)
    image = Column(String, nullable=True)
    subcategories = relationship("Subcategory", back_populates="category", cascade="all, delete-orphan")
    products = relationship("Product", back_populates="category", cascade="all, delete-orphan")

class Subcategory(Base):
    __tablename__ = "subcategories"

    id = Column(BigInteger, primary_key=True, index=True, default=generate_16_digit_id, unique=True)
    name = Column(String, index=True, nullable=False)
    image = Column(String, nullable=True)
    category_id = Column(BigInteger, ForeignKey("categories.id"), nullable=False)
    category = relationship("Category", back_populates="subcategories")
    products = relationship("Product", back_populates="subcategory", cascade="all, delete-orphan")

class Product(Base):
    __tablename__ = "products"

    id = Column(BigInteger, primary_key=True, index=True, default=generate_16_digit_id, unique=True)
    name = Column(String, index=True, nullable=False)
    image = Column(String, nullable=True)
    category_id = Column(BigInteger, ForeignKey("categories.id"), nullable=False)
    subcategory_id = Column(BigInteger, ForeignKey("subcategories.id"), nullable=False)
    price = Column(Float, nullable=False)
    discount = Column(Float, default=0.0)
    final_price = Column(Float, nullable=False)

    category = relationship("Category", back_populates="products")
    subcategory = relationship("Subcategory", back_populates="products")

    cart_items = relationship("CartItem", back_populates="product", cascade="all, delete-orphan")

    # Optional: for order items too
    order_items = relationship("OrderItem", back_populates="product", cascade="all, delete-orphan")