from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.cart.models import CartItem
from app.auth.models import User
from app.admin.models import Product

router = APIRouter()

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/add")
def add_to_cart(user_id: int, product_id: int, quantity: int, db: Session = Depends(get_db)):
    # check if user exists
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # check if product exists
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    # check if already in cart
    cart_item = db.query(CartItem).filter_by(user_id=user_id, product_id=product_id).first()
    if cart_item:
        cart_item.quantity += quantity
    else:
        cart_item = CartItem(user_id=user_id, product_id=product_id, quantity=quantity)
        db.add(cart_item)

    db.commit()
    return {"message": "Item added to cart"}


@router.put("/update")
def update_cart_item(user_id: int, product_id: int, quantity: int, db: Session = Depends(get_db)):
    cart_item = db.query(CartItem).filter_by(user_id=user_id, product_id=product_id).first()
    if not cart_item:
        raise HTTPException(status_code=404, detail="Item not in cart")

    if quantity <= 0:
        db.delete(cart_item)
        db.commit()
        return {"message": "Item removed from cart because quantity was set to 0"}

    cart_item.quantity = quantity
    db.commit()
    return {"message": "Cart item updated"}

@router.delete("/remove")
def remove_cart_item(user_id: int, product_id: int, db: Session = Depends(get_db)):
    cart_item = db.query(CartItem).filter_by(user_id=user_id, product_id=product_id).first()
    if not cart_item:
        raise HTTPException(status_code=404, detail="Item not in cart")

    db.delete(cart_item)
    db.commit()
    return {"message": "Item removed from cart"}


@router.get("/items")
def get_cart_items(user_id: int, db: Session = Depends(get_db)):
    cart_items = db.query(CartItem).filter_by(user_id=user_id).all()
    result = []

    for item in cart_items:
        result.append({
            "product_id": item.product_id,
            "quantity": item.quantity
        })

    return {"cart": result}


@router.delete("/clear")
def clear_cart(user_id: int, db: Session = Depends(get_db)):
    cart_items = db.query(CartItem).filter_by(user_id=user_id).all()
    if not cart_items:
        return {"message": "Cart already empty"}

    for item in cart_items:
        db.delete(item)

    db.commit()
    return {"message": "Cart cleared"}