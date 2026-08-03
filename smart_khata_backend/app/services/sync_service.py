from typing import Dict, Any, List, Optional
from app.database import get_database
from app.models.schemas import SyncPushPayload, utc_now_iso
from app.services.order_service import create_order
from app.services.employee_service import mark_attendance

async def pull_catalogue_changes(since_timestamp: Optional[str] = None) -> Dict[str, Any]:
    db = get_database()
    query = {}
    if since_timestamp:
        query = {"updated_at": {"$gte": since_timestamp}}

    p_cursor = db["products"].find(query)
    products = await p_cursor.to_list(2000)
    for p in products:
        p["id"] = p["_id"]

    s_cursor = db["suppliers"].find(query)
    suppliers = await s_cursor.to_list(2000)
    for s in suppliers:
        s["id"] = s["_id"]

    c_cursor = db["customers"].find(query)
    customers = await c_cursor.to_list(2000)
    for c in customers:
        c["id"] = c["_id"]

    e_cursor = db["employees"].find(query)
    employees = await e_cursor.to_list(2000)
    for e in employees:
        e["id"] = e["_id"]

    return {
        "products": products,
        "suppliers": suppliers,
        "customers": customers,
        "employees": employees,
        "server_timestamp": utc_now_iso()
    }

async def push_offline_batch(payload: SyncPushPayload) -> Dict[str, Any]:
    results = []

    # 1. Process Offline Orders
    for order_data in payload.orders:
        client_id = order_data.client_id
        try:
            order_res = await create_order(order_data)
            results.append({
                "client_id": client_id,
                "entity_type": "order",
                "status": "success",
                "message": "Order synced successfully.",
                "data": order_res
            })
        except ValueError as ve:
            # Per-item stock shortfall or validation error
            results.append({
                "client_id": client_id,
                "entity_type": "order",
                "status": "failed",
                "message": str(ve),
                "data": None
            })
        except Exception as e:
            results.append({
                "client_id": client_id,
                "entity_type": "order",
                "status": "failed",
                "message": f"Unexpected error: {str(e)}",
                "data": None
            })

    # 2. Process Offline Attendance
    for att_data in payload.attendance:
        try:
            att_res = await mark_attendance(att_data)
            results.append({
                "client_id": None,
                "entity_type": "attendance",
                "status": "success",
                "message": f"Attendance for {att_data.date} synced.",
                "data": att_res
            })
        except Exception as e:
            results.append({
                "client_id": None,
                "entity_type": "attendance",
                "status": "failed",
                "message": str(e),
                "data": None
            })

    return {"results": results}
