from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import (
    auth, inventory, suppliers, customers, orders,
    employees, attendance, payroll, cashbook, reports,
    forecast, restock, ai, sync, invoice, backup
)

app = FastAPI(
    title="Smart Khata API",
    description="AI-Powered Shop Management Backend for Pakistani Kiryana Stores",
    version="1.0.0"
)

# Enable CORS for Flutter mobile client and Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router)
app.include_router(inventory.router)
app.include_router(suppliers.router)
app.include_router(customers.router)
app.include_router(orders.router)
app.include_router(employees.router)
app.include_router(attendance.router)
app.include_router(payroll.router)
app.include_router(cashbook.router)
app.include_router(reports.router)
app.include_router(forecast.router)
app.include_router(restock.router)
app.include_router(ai.router)
app.include_router(sync.router)
app.include_router(invoice.router)
app.include_router(backup.router)

@app.on_event("startup")
async def seed_default_users():
    from app.database import get_database
    from app.auth.security import hash_password
    import uuid

    db = get_database()
    # Seed Owner / Admin Account if not exists
    existing_owner = await db["users"].find_one({"username": "admin"})
    if not existing_owner:
        await db["users"].insert_one({
            "_id": str(uuid.uuid4()),
            "username": "admin",
            "hashed_password": hash_password("admin123"),
            "name": "Tariq Kiryana Owner",
            "role": "owner",
            "employee_id": None
        })

    # Seed Employee / Staff Account if not exists
    existing_staff = await db["users"].find_one({"username": "staff"})
    if not existing_staff:
        await db["users"].insert_one({
            "_id": str(uuid.uuid4()),
            "username": "staff",
            "hashed_password": hash_password("staff123"),
            "name": "Ali Cashier",
            "role": "employee",
            "employee_id": "EMP-101"
        })

@app.get("/")
async def root():
    return {
        "status": "online",
        "app": "Smart Khata API",
        "version": "1.0.0",
        "docs_url": "/docs"
    }
