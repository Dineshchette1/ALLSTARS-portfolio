from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.database import SessionLocal
from app.admin.models import Category, Subcategory, Product
from app.admin.schemas import (
    CategoryCreate, Category as CategorySchema,
    SubcategoryCreate, Subcategory as SubcategorySchema,
    ProductCreate, Product as ProductSchema
)


router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/categories/", response_model=CategorySchema)
def create_category(category: CategoryCreate, db: Session = Depends(get_db)):
    db_category = db.query(Category).filter(Category.name == category.name).first()
    if db_category:
        raise HTTPException(status_code=400, detail="Category already exists")
    new_category = Category(name=category.name, image=category.image)
    db.add(new_category)
    db.commit()
    db.refresh(new_category)
    return new_category

@router.get("/categories/", response_model=List[CategorySchema])
def read_categories(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return db.query(Category).offset(skip).limit(limit).all()

@router.get("/categories/{category_id}", response_model=CategorySchema)
def read_category(category_id: int, db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    return category

@router.put("/categories/{category_id}", response_model=CategorySchema)
def update_category(category_id: int, updated: CategoryCreate, db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    category.name = updated.name
    category.image = updated.image
    db.commit()
    db.refresh(category)
    return category

@router.delete("/categories/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(category_id: int, db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    db.delete(category)
    db.commit()

# ----------------------- Subcategory CRUD -----------------------

@router.post("/subcategories/", response_model=SubcategorySchema)
def create_subcategory(subcat: SubcategoryCreate, db: Session = Depends(get_db)):
    new_subcat = Subcategory(
        name=subcat.name,
        image=subcat.image,
        category_id=subcat.category_id
    )
    db.add(new_subcat)
    db.commit()
    db.refresh(new_subcat)
    return new_subcat

@router.get("/subcategories/", response_model=List[SubcategorySchema])
def read_subcategories(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return db.query(Subcategory).offset(skip).limit(limit).all()

@router.get("/subcategories/{subcategory_id}", response_model=SubcategorySchema)
def read_subcategory(subcategory_id: int, db: Session = Depends(get_db)):
    subcat = db.query(Subcategory).filter(Subcategory.id == subcategory_id).first()
    if not subcat:
        raise HTTPException(status_code=404, detail="Subcategory not found")
    return subcat

@router.put("/subcategories/{subcategory_id}", response_model=SubcategorySchema)
def update_subcategory(subcategory_id: int, updated: SubcategoryCreate, db: Session = Depends(get_db)):
    subcat = db.query(Subcategory).filter(Subcategory.id == subcategory_id).first()
    if not subcat:
        raise HTTPException(status_code=404, detail="Subcategory not found")
    subcat.name = updated.name
    subcat.image = updated.image
    subcat.category_id = updated.category_id
    db.commit()
    db.refresh(subcat)
    return subcat

@router.delete("/subcategories/{subcategory_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_subcategory(subcategory_id: int, db: Session = Depends(get_db)):
    subcat = db.query(Subcategory).filter(Subcategory.id == subcategory_id).first()
    if not subcat:
        raise HTTPException(status_code=404, detail="Subcategory not found")
    db.delete(subcat)
    db.commit()

# ----------------------- Product CRUD -----------------------

@router.post("/products/", response_model=ProductSchema)
def create_product(product: ProductCreate, db: Session = Depends(get_db)):
    new_product = Product(
        name=product.name,
        image=product.image,
        category_id=product.category_id,
        subcategory_id=product.subcategory_id,
        price=product.price,
        discount=product.discount,
        final_price=product.final_price
    )
    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    return new_product

@router.get("/products/", response_model=List[ProductSchema])
def read_products(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return db.query(Product).offset(skip).limit(limit).all()

@router.get("/products/{product_id}", response_model=ProductSchema)
def read_product(product_id: int, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@router.put("/products/{product_id}", response_model=ProductSchema)
def update_product(product_id: int, updated: ProductCreate, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    product.name = updated.name
    product.image = updated.image
    product.category_id = updated.category_id
    product.subcategory_id = updated.subcategory_id
    product.price = updated.price
    product.discount = updated.discount
    product.final_price = updated.final_price
    db.commit()
    db.refresh(product)
    return product

@router.delete("/products/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_product(product_id: int, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    db.delete(product)
    db.commit()
