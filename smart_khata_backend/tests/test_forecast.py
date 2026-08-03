import pytest  # type: ignore
from datetime import datetime, timedelta, timezone
from httpx import AsyncClient  # type: ignore
from app.database import get_database

@pytest.mark.asyncio
async def test_scikit_learn_demand_forecasting(client: AsyncClient, owner_headers):
    p_res = await client.post("/api/products", json={
        "name": "Atta 10kg",
        "category": "Flour",
        "unit": "bag",
        "buying_price": 900.0,
        "selling_price": 1100.0,
        "current_stock": 50.0,
        "low_stock_threshold": 10.0
    }, headers=owner_headers)
    prod_id = p_res.json()["id"]

    db = get_database()
    now_dt = datetime.now(timezone.utc)

    for day_offset in range(30):
        order_date = (now_dt - timedelta(days=day_offset)).isoformat()
        await db["orders"].insert_one({
            "_id": f"seed_order_{day_offset}",
            "line_items": [
                {
                    "product_id": prod_id,
                    "product_name": "Atta 10kg",
                    "buying_price": 900.0,
                    "unit_price": 1100.0,
                    "quantity": 2.0,
                    "line_total": 2200.0
                }
            ],
            "subtotal": 2200.0,
            "discount": 0.0,
            "total_amount": 2200.0,
            "payment_method": "cash",
            "amount_paid_now": 2200.0,
            "amount_added_to_khata": 0.0,
            "created_at": order_date
        })

    forecast_res = await client.get("/api/forecast", headers=owner_headers)
    assert forecast_res.status_code == 200
    data = forecast_res.json()
    forecasts = data["forecasts"]

    atta_forecast = next((f for f in forecasts if f["product_id"] == prod_id), None)
    assert atta_forecast is not None
    assert atta_forecast["method_used"] == "linear_regression"
    assert atta_forecast["historical_days_with_sales"] == 30

    pred_demand = atta_forecast["predicted_7day_demand"]
    assert 12.5 <= pred_demand <= 15.5
    assert atta_forecast["needs_restock"] is False

    p_b_res = await client.post("/api/products", json={
        "name": "New Spice Pack",
        "category": "Spices",
        "unit": "pack",
        "buying_price": 50.0,
        "selling_price": 80.0,
        "current_stock": 2.0,
        "low_stock_threshold": 5.0
    }, headers=owner_headers)
    prod_b_id = p_b_res.json()["id"]

    forecast_res_2 = await client.get("/api/forecast", headers=owner_headers)
    spice_forecast = next((f for f in forecast_res_2.json()["forecasts"] if f["product_id"] == prod_b_id), None)
    assert spice_forecast is not None
    assert spice_forecast["method_used"] == "threshold_fallback"
    assert spice_forecast["needs_restock"] is True
