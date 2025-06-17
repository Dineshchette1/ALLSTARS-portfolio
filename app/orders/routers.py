from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.database import SessionLocal
from app.orders.models import Order, OrderItem, Address,PaymentStatusEnum
from app.orders.schemas import OrderCreate, OrderRead, AddressCreate, AddressRead


router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=OrderRead, status_code=status.HTTP_201_CREATED)
def create_order(order: OrderCreate, db: Session = Depends(get_db)):

    db_address = Address(user_id=order.user_id, **order.shipping_address.dict())
    db.add(db_address)
    db.commit()
    db.refresh(db_address)

    db_order = Order(
        user_id=order.user_id,
        total_amount=order.total_amount,
        discount_amount=order.discount_amount,
        final_amount=order.final_amount,
        payment_status=order.payment_status,
        shipping_address_id=db_address.id
    )
    db.add(db_order)
    db.commit()
    db.refresh(db_order)


    for item in order.order_items:
        db_item = OrderItem(
            order_id=db_order.id,
            product_id=item.product_id,
            quantity=item.quantity,
            price_per_unit=item.price_per_unit,
            discount_per_unit=item.discount_per_unit,
            final_price_per_unit=item.final_price_per_unit,
        )
        db.add(db_item)
    db.commit()

    db.refresh(db_order)
    return db_order

@router.get("/{order_id}", response_model=OrderRead)
def get_order(order_id: int, db: Session = Depends(get_db)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order


@router.get("/", response_model=List[OrderRead])
def list_orders(user_id: int = None, db: Session = Depends(get_db)):
    query = db.query(Order)
    if user_id:
        query = query.filter(Order.user_id == user_id)
    return query.all()


@router.patch("/{order_id}/payment_status", response_model=OrderRead)
def update_payment_status(order_id: int, payment_status: PaymentStatusEnum, db: Session = Depends(get_db)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    order.payment_status = payment_status
    db.commit()
    db.refresh(order)
    return order

@router.delete("/{order_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_order(order_id: int, db: Session = Depends(get_db)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    db.delete(order)
    db.commit()
    return None
