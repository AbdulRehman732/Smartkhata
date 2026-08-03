import math
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any
import numpy as np
from sklearn.linear_model import LinearRegression

from app.database import get_database
from app.models.schemas import utc_now_iso
from app.services.inventory_service import get_products

async def generate_demand_forecast() -> Dict[str, Any]:
    db = get_database()
    now_dt = datetime.now(timezone.utc)
    thirty_days_ago = now_dt - timedelta(days=30)
    thirty_days_ago_str = thirty_days_ago.isoformat()

    # 1. Fetch all products
    products = await get_products()

    # 2. Fetch orders from the last 30 days
    cursor = db["orders"].find({"created_at": {"$gte": thirty_days_ago_str}})
    recent_orders = await cursor.to_list(10000)

    # 3. Aggregate daily quantity sold per product for days 0..29
    # Day 0 is 29 days ago, Day 29 is today
    product_daily_sales: Dict[str, Dict[int, float]] = {p["id"]: {d: 0.0 for d in range(30)} for p in products}

    for order in recent_orders:
        created_at_str = order.get("created_at")
        if not created_at_str:
            continue
        try:
            order_dt = datetime.fromisoformat(created_at_str.replace("Z", "+00:00"))
        except Exception:
            continue

        days_diff = (now_dt.date() - order_dt.date()).days
        if 0 <= days_diff < 30:
            day_idx = 29 - days_diff # 0 is 29 days ago, 29 is today
            for line in order.get("line_items", []):
                p_id = line.get("product_id")
                qty = line.get("quantity", 0.0)
                if p_id in product_daily_sales:
                    product_daily_sales[p_id][day_idx] += qty

    forecast_items: List[Dict[str, Any]] = []

    for p in products:
        p_id = p["id"]
        daily_series = [product_daily_sales[p_id][d] for d in range(30)]
        
        distinct_sale_days = sum(1 for qty in daily_series if qty > 0)
        total_qty_sold_30d = sum(daily_series)
        avg_daily_sales = total_qty_sold_30d / 30.0

        curr_stock = p.get("current_stock", 0.0)
        threshold = p.get("low_stock_threshold", 5.0)

        if distinct_sale_days >= 5:
            # Fit scikit-learn LinearRegression model: X (day index 0..29), Y (quantity sold)
            X = np.array(range(30)).reshape(-1, 1)
            y = np.array(daily_series)

            model = LinearRegression()
            model.fit(X, y)

            # Predict demand for next 7 days (days 30 to 36)
            next_7_days_X = np.array(range(30, 37)).reshape(-1, 1)
            predicted_daily = model.predict(next_7_days_X)
            # Clip negative predictions to 0
            predicted_daily_clipped = np.clip(predicted_daily, 0, None)
            predicted_7day_demand = float(np.sum(predicted_daily_clipped))
            method_used = "linear_regression"
        else:
            # Fallback rule for insufficient history
            predicted_7day_demand = round(avg_daily_sales * 7, 2)
            method_used = "threshold_fallback"

        # Determine restock flag
        needs_restock = False
        suggested_reorder_qty = 0.0

        if method_used == "linear_regression":
            if predicted_7day_demand > curr_stock:
                needs_restock = True
                suggested_reorder_qty = math.ceil(predicted_7day_demand - curr_stock)
            elif curr_stock <= threshold:
                needs_restock = True
                suggested_reorder_qty = math.ceil(max(threshold * 2 - curr_stock, predicted_7day_demand))
        else:
            if curr_stock <= threshold:
                needs_restock = True
                suggested_reorder_qty = math.ceil(max(threshold * 2 - curr_stock, 10.0))

        forecast_items.append({
            "product_id": p_id,
            "product_name": p["name"],
            "current_stock": curr_stock,
            "low_stock_threshold": threshold,
            "historical_days_with_sales": distinct_sale_days,
            "avg_daily_sales": round(avg_daily_sales, 2),
            "predicted_7day_demand": round(predicted_7day_demand, 2),
            "needs_restock": needs_restock,
            "suggested_reorder_qty": float(suggested_reorder_qty),
            "method_used": method_used
        })

    return {
        "forecasts": forecast_items,
        "generated_at": utc_now_iso()
    }
