import pytest  # type: ignore
from httpx import AsyncClient  # type: ignore

@pytest.mark.asyncio
async def test_order_stock_prevalidation_and_khata(client: AsyncClient, owner_headers):
    res_a = await client.post("/api/products", json={
        "name": "Sugar 1kg",
        "category": "Grocery",
        "unit": "kg",
        "buying_price": 120.0,
        "selling_price": 150.0,
        "current_stock": 10.0,
        "low_stock_threshold": 2.0
    }, headers=owner_headers)
    prod_a_id = res_a.json()["id"]

    res_b = await client.post("/api/products", json={
        "name": "Cooking Oil 1L",
        "category": "Oil",
        "unit": "litre",
        "buying_price": 450.0,
        "selling_price": 500.0,
        "current_stock": 2.0,
        "low_stock_threshold": 1.0
    }, headers=owner_headers)
    prod_b_id = res_b.json()["id"]

    res_c = await client.post("/api/customers", json={
        "name": "Chaudhry Ahmad",
        "phone": "03001234567",
        "type": "regular"
    }, headers=owner_headers)
    cust_id = res_c.json()["id"]

    short_order = await client.post("/api/orders", json={
        "line_items": [
            {"product_id": prod_a_id, "quantity": 5.0},
            {"product_id": prod_b_id, "quantity": 5.0}
        ],
        "discount": 0.0,
        "payment_method": "credit",
        "customer_id": cust_id
    }, headers=owner_headers)

    assert short_order.status_code == 400
    err_detail = short_order.json()["detail"]
    assert "Insufficient stock for product 'Cooking Oil 1L'" in err_detail
    assert "Shortfall: 3.0" in err_detail

    get_a = await client.get(f"/api/products/{prod_a_id}", headers=owner_headers)
    assert get_a.json()["current_stock"] == 10.0

    valid_order = await client.post("/api/orders", json={
        "line_items": [
            {"product_id": prod_a_id, "quantity": 2.0}
        ],
        "discount": 0.0,
        "payment_method": "partial",
        "amount_paid_now": 100.0,
        "customer_id": cust_id
    }, headers=owner_headers)

    assert valid_order.status_code == 200
    order_data = valid_order.json()
    assert order_data["total_amount"] == 300.0
    assert order_data["amount_paid_now"] == 100.0
    assert order_data["amount_added_to_khata"] == 200.0

    get_cust = await client.get(f"/api/customers/{cust_id}", headers=owner_headers)
    assert get_cust.json()["balance_due"] == 200.0

    pay_res = await client.post("/api/customers/payments", json={
        "customer_id": cust_id,
        "amount": 150.0,
        "note": "Partial cash payment"
    }, headers=owner_headers)
    assert pay_res.status_code == 200

    get_cust_2 = await client.get(f"/api/customers/{cust_id}", headers=owner_headers)
    assert get_cust_2.json()["balance_due"] == 50.0

    hist_res = await client.get(f"/api/customers/{cust_id}/history", headers=owner_headers)
    assert hist_res.status_code == 200
    history = hist_res.json()
    assert len(history) == 2
    types = [item["type"] for item in history]
    assert "sale_credit" in types
    assert "payment_received" in types
