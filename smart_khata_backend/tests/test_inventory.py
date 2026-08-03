import pytest  # type: ignore
from httpx import AsyncClient  # type: ignore

@pytest.mark.asyncio
async def test_product_crud_and_stock_adjustment(client: AsyncClient, owner_headers):
    res = await client.post("/api/products", json={
        "name": "Basmati Rice 5kg",
        "urdu_name": "چاول 5 کلو",
        "category": "Grains",
        "unit": "kg",
        "buying_price": 1000.0,
        "selling_price": 1250.0,
        "current_stock": 20.0,
        "low_stock_threshold": 5.0
    }, headers=owner_headers)
    assert res.status_code == 200
    prod = res.json()
    prod_id = prod["id"]
    assert prod["current_stock"] == 20.0

    search_res = await client.get("/api/products?search=چاول", headers=owner_headers)
    assert search_res.status_code == 200
    assert len(search_res.json()) == 1

    adj_res = await client.post("/api/products/adjust-stock", json={
        "product_id": prod_id,
        "quantity_change": -5.0,
        "reason": "Spoilage"
    }, headers=owner_headers)
    assert adj_res.status_code == 200
    assert adj_res.json()["current_stock"] == 15.0

    fail_adj = await client.post("/api/products/adjust-stock", json={
        "product_id": prod_id,
        "quantity_change": -50.0,
        "reason": "Excess deduction"
    }, headers=owner_headers)
    assert fail_adj.status_code == 400
    assert "Stock cannot be negative" in fail_adj.json()["detail"]
