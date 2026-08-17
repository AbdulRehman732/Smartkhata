import uuid
from typing import List, Optional, Dict, Any
from app.database import get_database
from app.models.schemas import OrderCreate, utc_now_iso
from app.services.inventory_service import get_product_by_id, adjust_stock
from app.services.customer_service import get_customer_by_id

async def create_order(order_data: OrderCreate) -> Dict[str, Any]:
    db = get_database()
    now = utc_now_iso()

    # 1. Idempotency Check (if client_id is provided)
    if order_data.client_id:
        existing = await db["orders"].find_one({"client_id": order_data.client_id})
        if existing:
            existing["id"] = existing["_id"]
            return existing

    # 2. Validate Customer Requirement
    customer = None
    if order_data.payment_method in ["credit", "partial"]:
        if not order_data.customer_id:
            raise ValueError(f"A customer is required for {order_data.payment_method} orders.")
        customer = await get_customer_by_id(order_data.customer_id)
        if not customer:
            raise ValueError(f"Customer with ID '{order_data.customer_id}' not found.")
    elif order_data.customer_id:
        customer = await get_customer_by_id(order_data.customer_id)

    # 3. Product Lookup & Stock Pre-Validation Phase across ALL line items
    validated_lines = []
    subtotal = 0.0

    for item in order_data.line_items:
        prod = await get_product_by_id(item.product_id)
        if not prod:
            raise ValueError(f"Product with ID '{item.product_id}' not found.")
        
        req_qty = item.quantity
        curr_stock = prod.get("current_stock", 0.0)

        # STRICT CHECK: Reject whole order if stock is insufficient
        if curr_stock < req_qty:
            shortfall = req_qty - curr_stock
            raise ValueError(
                f"Insufficient stock for product '{prod['name']}'. Requested: {req_qty}, Available: {curr_stock}. Shortfall: {shortfall}."
            )
        
        unit_price = prod.get("selling_price") or prod.get("sale_price") or 0.0
        line_total = req_qty * unit_price
        subtotal += line_total

        validated_lines.append({
            "product_id": item.product_id,
            "product_name": prod["name"],
            "category": prod.get("category", ""),
            "buying_price": prod.get("buying_price", 0.0),
            "unit_price": unit_price,
            "quantity": req_qty,
            "line_total": line_total
        })

    # 4. Total and Payment Validation
    total_amount = max(0.0, subtotal - order_data.discount)
    payment_method = order_data.payment_method.lower()

    if payment_method == "cash":
        amount_paid_now = total_amount
        amount_added_to_khata = 0.0
    elif payment_method == "credit":
        amount_paid_now = 0.0
        amount_added_to_khata = total_amount
    elif payment_method == "partial":
        amount_paid_now = order_data.amount_paid_now
        if amount_paid_now > total_amount:
            amount_paid_now = total_amount
        amount_added_to_khata = total_amount - amount_paid_now
    else:
        raise ValueError(f"Invalid payment method '{order_data.payment_method}'. Must be cash, credit, or partial.")

    # 5. Stock Deduction Phase (only AFTER all lines pass validation)
    for line in validated_lines:
        await adjust_stock(
            product_id=str(line["product_id"]),
            quantity_change=-float(line["quantity"]),
            reason="Sale order deduction"
        )

    # 6. Update Customer Khata Balance (if credit/partial)
    if amount_added_to_khata > 0 and customer:
        await db["customers"].update_one(
            {"_id": customer["id"]},
            {
                "$inc": {"balance_due": amount_added_to_khata},
                "$set": {"updated_at": now}
            }
        )

    # 7. Construct and Save Order Record
    order_id = str(uuid.uuid4())
    order_doc = {
        "_id": order_id,
        "line_items": validated_lines,
        "subtotal": subtotal,
        "discount": order_data.discount,
        "total_amount": total_amount,
        "payment_method": payment_method,
        "amount_paid_now": amount_paid_now,
        "amount_added_to_khata": amount_added_to_khata,
        "customer_id": order_data.customer_id,
        "customer_name": customer["name"] if customer else None,
        "created_at": now,
        "client_id": order_data.client_id
    }
    await db["orders"].insert_one(order_doc)
    order_doc["id"] = order_id
    return order_doc

async def get_orders(limit: int = 100) -> List[Dict[str, Any]]:
    db = get_database()
    cursor = db["orders"].find({}).sort("created_at", -1).limit(limit)
    orders = await cursor.to_list(limit)
    for o in orders:
        o["id"] = o["_id"]
    return orders

async def get_order_by_id(order_id: str) -> Optional[Dict[str, Any]]:
    db = get_database()
    doc = await db["orders"].find_one({"_id": order_id})
    if doc:
        doc["id"] = doc["_id"]
    return doc
