from sqlalchemy import create_engine, Column, Integer, String, DateTime, Enum
from sqlalchemy.orm import declarative_base
from datetime import datetime
import enum

DATABASE_URL = "postgresql+psycopg2://postgres:CHANGE_ME@localhost:5432/capstone_db"

engine = create_engine(DATABASE_URL)
Base = declarative_base()

class UserRole(enum.Enum):
    CUSTOMER = "CUSTOMER"
    ADMIN = "ADMIN"

class User(Base):
    __tablename__ = "My_user2"
    id = Column(Integer, primary_key=True)
    username = Column(String)
    mobile = Column(String, unique=True)
    password = Column(String)
    last_login = Column(DateTime, default=datetime.utcnow)
    role = Column(Enum(UserRole), default=UserRole.CUSTOMER)

print("Creating tables...")
Base.metadata.create_all(bind=engine)
print("Tables created!")
