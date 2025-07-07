import enum
import random
from datetime import datetime
from sqlalchemy import create_engine ,Column, String, BigInteger, DateTime, Enum as SQLAlchemyEnum
from app.database import Base  # import Base from database.py
from sqlalchemy.orm import declarative_base

# DATABASE_URL = "postgresql+psycopg2://postgres:CHANGE_ME@localhost:5432/capstone_db"
#
# engine = create_engine(DATABASE_URL)
#Base = declarative_base()

def generate_unique_id():
    return random.randint(10**15, (10**16) - 1)


class UserRole(enum.Enum):
    CUSTOMER = "CUSTOMER"
    ADMIN = "ADMIN"


from sqlalchemy.orm import relationship

class User(Base):
    __tablename__ = "CapstoneUsers"

    id = Column(
        BigInteger,
        primary_key=True,
        index=True,
        default=generate_unique_id,
        unique=True
    )
    username = Column(String)
    mobile = Column(String, unique=True)
    last_login = Column(DateTime, default=datetime.utcnow)
    role = Column(SQLAlchemyEnum(UserRole), default=UserRole.CUSTOMER)


    cart_items = relationship("CartItem", back_populates="user", cascade="all, delete-orphan")
    orders = relationship("Order", back_populates="user", cascade="all, delete-orphan")
    addresses = relationship("Address", back_populates="user", cascade="all, delete-orphan")


# print("Creating tables...")
# Base.metadata.create_all(bind=engine)
# print("Tables created!")