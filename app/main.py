from fastapi import FastAPI
from app.auth.routers import router as auth_router
from app.admin.routers import router as admin_router
from app.users.routers import router as users_router
from app.products.routers import router as products_router
from app.cart.routers import router as cart_router
from app.orders.routers import router as orders_router

app = FastAPI(title="Ecommerce Capstone Project")

# Include routers
app.include_router(auth_router, prefix="/auth", tags=["Auth"])
app.include_router(admin_router, prefix="/admin", tags=["Admin"])
app.include_router(users_router, prefix="/users", tags=["Users"])
app.include_router(products_router, prefix="/products", tags=["Products"])
app.include_router(cart_router, prefix="/cart", tags=["Cart"])
app.include_router(orders_router, prefix="/orders", tags=["Orders"])
