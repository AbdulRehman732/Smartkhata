from typing import Dict, Any
from app.database import get_database
from app.models.schemas import utc_now_iso

async def generate_full_backup() -> Dict[str, Any]:
    db = get_database()

    products = await db["products"].find({}).to_list(10000)
    suppliers = await db["suppliers"].find({}).to_list(10000)
    customers = await db["customers"].find({}).to_list(10000)
    orders = await db["orders"].find({}).to_list(10000)
    employees = await db["employees"].find({}).to_list(10000)
    attendance = await db["attendance"].find({}).to_list(10000)
    expenses = await db["expenses"].find({}).to_list(10000)

    for col in [products, suppliers, customers, orders, employees, attendance, expenses]:
        for doc in col:
            doc["id"] = doc.get("_id", doc.get("id"))

    return {
        "version": "1.0",
        "exported_at": utc_now_iso(),
        "products": products,
        "suppliers": suppliers,
        "customers": customers,
        "orders": orders,
        "employees": employees,
        "attendance": attendance,
        "expenses": expenses
    }

async def restore_from_backup(backup_data: Dict[str, Any]) -> Dict[str, Any]:
    db = get_database()

    restored_counts = {}
    collections = ["products", "suppliers", "customers", "orders", "employees", "attendance", "expenses"]

    for col_name in collections:
        items = backup_data.get(col_name, [])
        count = 0
        for item in items:
            item_id = item.get("id") or item.get("_id")
            if item_id:
                item["_id"] = item_id
                await db[col_name].update_one({"_id": item_id}, {"$set": item}, upsert=True)
                count += 1
        restored_counts[col_name] = count

    return {
        "status": "success",
        "restored_at": utc_now_iso(),
        "counts": restored_counts
    }
