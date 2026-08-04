from typing import Dict, Any, List
from app.services.inventory_service import get_products
from app.services.forecast_service import generate_demand_forecast

async def calculate_smart_restock_recommendations(
    lead_time_days: int = 3,
    safety_stock_percent: float = 0.20
) -> Dict[str, Any]:
    """
    Smart Restock AI (#13):
    Evaluates product stock, Scikit-Learn demand velocity forecasts,
    lead times, and safety buffer to recommend intelligent reorder orders.
    """
    products = await get_products()
    forecast_result = await generate_demand_forecast()
    forecast_map = {item["product_id"]: item for item in forecast_result.get("forecasts", [])}

    recommendations: List[Dict[str, Any]] = []

    for p in products:
        pid = p["id"]
        current_stock = float(p.get("current_stock", 0.0))
        threshold = float(p.get("low_stock_threshold", 5.0))
        
        forecast_info = forecast_map.get(pid, {})
        projected_7d = float(forecast_info.get("predicted_demand_7d", 0.0))
        daily_velocity = projected_7d / 7.0 if projected_7d > 0 else 0.5

        # Lead time demand + safety stock buffer
        lead_time_demand = daily_velocity * lead_time_days
        safety_buffer = lead_time_demand * safety_stock_percent
        reorder_point = max(threshold, round(lead_time_demand + safety_buffer, 2))

        needs_reorder = current_stock <= reorder_point
        suggested_qty = max(0.0, round((reorder_point * 2) - current_stock, 2)) if needs_reorder else 0.0

        recommendations.append({
            "product_id": pid,
            "product_name": p["name"],
            "unit": p.get("unit", "pcs"),
            "current_stock": current_stock,
            "reorder_point": reorder_point,
            "daily_sales_velocity": round(daily_velocity, 2),
            "projected_demand_7d": round(projected_7d, 2),
            "needs_restock": needs_reorder,
            "suggested_reorder_qty": suggested_qty,
            "priority": "HIGH" if current_stock == 0 else ("MEDIUM" if needs_reorder else "LOW")
        })

    return {
        "lead_time_days": lead_time_days,
        "safety_stock_percent": safety_stock_percent,
        "total_products_checked": len(products),
        "items_needing_restock": sum(1 for r in recommendations if r["needs_restock"]),
        "recommendations": recommendations
    }
