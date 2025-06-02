from pydantic import BaseModel
from typing import Optional, List


class CategoryBase(BaseModel):
    name: str
    image: Optional[str] = None


class CategoryCreate(CategoryBase):
    pass


class Category(CategoryBase):
    id: int

    class Config:
        from_attributes = True


class SubcategoryBase(BaseModel):
    name: str
    image: Optional[str] = None
    category_id: int


class SubcategoryCreate(SubcategoryBase):
    pass


class Subcategory(SubcategoryBase):
    id: int

    class Config:
        from_attributes = True


class ProductBase(BaseModel):
    name: str
    image: Optional[str] = None
    category_id: int
    subcategory_id: int
    price: float
    discount: float = 0.0
    final_price: float


class ProductCreate(ProductBase):
    pass


class Product(ProductBase):
    id: int

    class Config:
        from_attributes = True
