from sqlalchemy import Column, BigInteger, Integer, String, ForeignKey, Float, DateTime, Enum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
import random
from app.auth.models import User
from app.database import Base

def generate_16_digit_id():
    return random.randint(10**15, 10**16 - 1)

class PaymentStatusEnum(enum.Enum):
    PENDING = "PENDING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    REFUNDED = "REFUNDED"

class Order(Base):
    __tablename__ = "orders"

    id = Column(BigInteger, primary_key=True, default=generate_16_digit_id, unique=True, index=True)
    user_id = Column(BigInteger, ForeignKey("CapstoneUsers.id"), nullable=False)
    total_amount = Column(Float, nullable=False)
    discount_amount = Column(Float, default=0.0)
    final_amount = Column(Float, nullable=False)
    payment_status = Column(Enum(PaymentStatusEnum), default=PaymentStatusEnum.PENDING)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Foreign key to Address if using separate Address table
    shipping_address_id = Column(BigInteger, ForeignKey("addresses.id"), nullable=True)

    user = relationship("User", back_populates="orders")
    order_items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    shipping_address = relationship("Address")

class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(BigInteger, primary_key=True, default=generate_16_digit_id, unique=True, index=True)
    order_id = Column(BigInteger, ForeignKey("orders.id"), nullable=False)
    product_id = Column(BigInteger, ForeignKey("products.id"), nullable=False)
    quantity = Column(Integer, nullable=False, default=1)
    price_per_unit = Column(Float, nullable=False)
    discount_per_unit = Column(Float, default=0.0)
    final_price_per_unit = Column(Float, nullable=False)

    order = relationship("Order", back_populates="order_items")
    product = relationship("Product")

class Address(Base):
    __tablename__ = "addresses"

    id = Column(BigInteger, primary_key=True, default=generate_16_digit_id, unique=True, index=True)
    user_id = Column(BigInteger, ForeignKey("CapstoneUsers.id"), nullable=False)
    line1 = Column(String(255), nullable=False)
    line2 = Column(String(255), nullable=True)
    city = Column(String(100), nullable=False)
    state = Column(String(100), nullable=False)
    postal_code = Column(String(20), nullable=False)
    country = Column(String(100), nullable=False)

    user = relationship("User")