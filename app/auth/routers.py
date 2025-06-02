# app/auth/routes.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.auth import models, schemas

router = APIRouter()


# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/register", response_model=schemas.UserResponse)
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # Check if user with mobile already exists
    existing_user = db.query(models.User).filter(models.User.mobile == user.mobile).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already registered"
        )

    # Create new user
    new_user = models.User(
        username=user.username,
        mobile=user.mobile,
        role=models.UserRole.CUSTOMER  # default role
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user
