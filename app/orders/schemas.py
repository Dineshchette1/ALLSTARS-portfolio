from pydantic import BaseModel, Field
from typing import List, Optional
from enum import Enum
from datetime import datetime

class PaymentStatusEnum(str, Enum):
    PENDING = "PENDING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    REFUNDED = "REFUNDED"

class AddressCreate(BaseModel):
    line1: str
    line2: Optional[str]
    city: str
    state: str
    postal_code: str
    country: str

class AddressRead(AddressCreate):
    id: int
    user_id: int

    class Config:
        orm_mode = True

class OrderItemCreate(BaseModel):
    product_id: int
    quantity: int = 1
    price_per_unit: float
    discount_per_unit: Optional[float] = 0.0
    final_price_per_unit: float

class OrderItemRead(OrderItemCreate):
    id: int

    class Config:
        orm_mode = True

class OrderCreate(BaseModel):
    user_id: int
    total_amount: float
    discount_amount: Optional[float] = 0.0
    final_amount: float
    payment_status: PaymentStatusEnum = PaymentStatusEnum.PENDING
    shipping_address: AddressCreate
    order_items: List[OrderItemCreate]

class OrderRead(BaseModel):
    id: int
    user_id: int
    total_amount: float
    discount_amount: float
    final_amount: float
    payment_status: PaymentStatusEnum
    created_at: datetime
    updated_at: datetime
    shipping_address: AddressRead
    order_items: List[OrderItemRead]

    class Config:
        orm_mode = True

