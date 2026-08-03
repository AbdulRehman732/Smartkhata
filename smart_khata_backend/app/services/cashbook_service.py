import uuid
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from app.database import get_database
from app.models.schemas import ExpenseCreate, utc_now_iso

async def create_expense(data: ExpenseCreate) -> Dict[str, Any]:
    db = get_database()
    now = utc_now_iso()
    doc = data.model_dump()
    doc["_id"] = str(uuid.uuid4())
    doc["date"] = data.date or now
    if "payment_method" not in doc:
        doc["payment_method"] = "cash"
    await db["expenses"].insert_one(doc)
    doc["id"] = doc["_id"]
    return doc

async def get_expenses(category: Optional[str] = None) -> List[Dict[str, Any]]:
    db = get_database()
    query = {"category": category} if category else {}
    cursor = db["expenses"].find(query).sort("date", -1)
    expenses = await cursor.to_list(1000)
    for e in expenses:
        e["id"] = e["_id"]
    return expenses

async def get_cashbook_ledger() -> Dict[str, Any]:
    db = get_database()
    entries: List[Dict[str, Any]] = []

    wallet_balances: Dict[str, float] = {
        "cash": 0.0,
        "jazzcash": 0.0,
        "easypaisa": 0.0,
        "nayapay": 0.0,
        "bank": 0.0
    }

    # 1. Order immediate payments (inflows)
    order_cursor = db["orders"].find({"amount_paid_now": {"$gt": 0}})
    orders = await order_cursor.to_list(2000)
    for o in orders:
        method = o.get("payment_method", "cash").lower()
        if method in ["credit"]:
            method = "cash"
        elif method == "partial":
            method = "cash"
        
        if method not in wallet_balances:
            method = "cash"

        entries.append({
            "type": "inflow",
            "category": "order_sale",
            "description": f"Sale Payment (Order #{str(o['_id'])[:8]})",
            "amount": o["amount_paid_now"],
            "payment_method": method,
            "date": o.get("created_at", "")
        })

    # 2. Customer Khata payments (inflows)
    pay_cursor = db["customer_payments"].find({})
    payments = await pay_cursor.to_list(2000)
    for p in payments:
        method = p.get("payment_method", "cash").lower()
        if method not in wallet_balances:
            method = "cash"

        entries.append({
            "type": "inflow",
            "category": "khata_payment",
            "description": f"Customer Payment ({p.get('note', 'Khata payment')})",
            "amount": p["amount"],
            "payment_method": method,
            "date": p.get("date", "")
        })

    # 3. Expenses (outflows)
    exp_cursor = db["expenses"].find({})
    expenses = await exp_cursor.to_list(2000)
    for e in expenses:
        method = e.get("payment_method", "cash").lower()
        if method not in wallet_balances:
            method = "cash"

        entries.append({
            "type": "outflow",
            "category": e.get("category", "misc"),
            "description": f"Expense: {e.get('note', '')}",
            "amount": e["amount"],
            "payment_method": method,
            "date": e.get("date", "")
        })

    # Sort chronological ascending to compute running balances per wallet
    entries.sort(key=lambda x: x.get("date", ""))

    running_balance = 0.0
    total_inflow = 0.0
    total_outflow = 0.0

    for item in entries:
        method = item["payment_method"]
        if item["type"] == "inflow":
            total_inflow += item["amount"]
            running_balance += item["amount"]
            wallet_balances[method] += item["amount"]
        else:
            total_outflow += item["amount"]
            running_balance -= item["amount"]
            wallet_balances[method] -= item["amount"]
        item["running_balance"] = round(running_balance, 2)

    # Return newest-first for presentation
    entries_newest_first = list(reversed(entries))

    # Round wallet balances
    for k in wallet_balances:
        wallet_balances[k] = round(wallet_balances[k], 2)

    return {
        "entries": entries_newest_first,
        "total_inflow": round(total_inflow, 2),
        "total_outflow": round(total_outflow, 2),
        "running_balance": round(running_balance, 2),
        "wallet_balances": wallet_balances
    }

async def get_dashboard_metrics() -> Dict[str, Any]:
    db = get_database()
    today_prefix = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    order_cursor = db["orders"].find({"created_at": {"$regex": f"^{today_prefix}"}})
    today_orders = await order_cursor.to_list(1000)

    today_revenue = sum(o.get("total_amount", 0.0) for o in today_orders)
    cash_collected_from_orders = sum(o.get("amount_paid_now", 0.0) for o in today_orders)

    cogs = 0.0
    for o in today_orders:
        for item in o.get("line_items", []):
            buying_p = item.get("buying_price", 0.0)
            qty = item.get("quantity", 0.0)
            cogs += (buying_p * qty)

    today_profit = max(0.0, today_revenue - cogs)

    pay_cursor = db["customer_payments"].find({"date": {"$regex": f"^{today_prefix}"}})
    today_khata_payments = await pay_cursor.to_list(1000)
    cash_collected_from_khata = sum(p.get("amount", 0.0) for p in today_khata_payments)

    total_cash_collected = cash_collected_from_orders + cash_collected_from_khata

    prod_cursor = db["products"].find({})
    all_products = await prod_cursor.to_list(2000)
    total_products = len(all_products)
    low_stock_count = sum(1 for p in all_products if p.get("current_stock", 0) <= p.get("low_stock_threshold", 5))

    cust_cursor = db["customers"].find({"balance_due": {"$gt": 0}})
    pending_customers = await cust_cursor.to_list(2000)
    pending_khata_count = len(pending_customers)
    pending_khata_total = sum(c.get("balance_due", 0.0) for c in pending_customers)

    att_cursor = db["attendance"].find({
        "date": today_prefix,
        "status": {"$in": ["present", "half_day"]}
    })
    present_records = await att_cursor.to_list(500)
    employees_present_today = len(present_records)

    ledger_info = await get_cashbook_ledger()

    return {
        "today_revenue": round(today_revenue, 2),
        "today_profit": round(today_profit, 2),
        "cash_collected": round(total_cash_collected, 2),
        "order_count": len(today_orders),
        "total_products": total_products,
        "low_stock_count": low_stock_count,
        "pending_khata_count": pending_khata_count,
        "pending_khata_total": round(pending_khata_total, 2),
        "employees_present_today": employees_present_today,
        "wallet_balances": ledger_info.get("wallet_balances", {})
    }

async def get_financial_summary(start_date: str, end_date: str) -> Dict[str, Any]:
    db = get_database()

    query = {"created_at": {"$gte": start_date, "$lte": end_date + "T23:59:59"}}
    order_cursor = db["orders"].find(query)
    orders = await order_cursor.to_list(5000)

    total_revenue = sum(o.get("total_amount", 0.0) for o in orders)
    cogs = 0.0
    for o in orders:
        for item in o.get("line_items", []):
            buying_p = item.get("buying_price", 0.0)
            qty = item.get("quantity", 0.0)
            cogs += (buying_p * qty)

    gross_profit = total_revenue - cogs

    exp_query = {"date": {"$gte": start_date, "$lte": end_date + "T23:59:59"}}
    exp_cursor = db["expenses"].find(exp_query)
    expenses = await exp_cursor.to_list(5000)
    total_expenses = sum(e.get("amount", 0.0) for e in expenses)

    net_profit = gross_profit - total_expenses
    ledger_info = await get_cashbook_ledger()

    return {
        "start_date": start_date,
        "end_date": end_date,
        "total_revenue": round(total_revenue, 2),
        "cost_of_goods_sold": round(cogs, 2),
        "gross_profit": round(gross_profit, 2),
        "total_expenses": round(total_expenses, 2),
        "net_profit": round(net_profit, 2),
        "wallet_balances": ledger_info.get("wallet_balances", {})
    }
