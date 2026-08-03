import pytest  # type: ignore
from httpx import AsyncClient  # type: ignore

@pytest.mark.asyncio
async def test_offline_sync_and_idempotency(client: AsyncClient, owner_headers):
    p_res = await client.post("/api/products", json={
        "name": "Milk Pack 1L",
        "category": "Dairy",
        "unit": "pack",
        "buying_price": 200.0,
        "selling_price": 250.0,
        "current_stock": 5.0
    }, headers=owner_headers)
    prod_id = p_res.json()["id"]

    pull_res = await client.get("/api/sync/pull", headers=owner_headers)
    assert pull_res.status_code == 200
    pull_data = pull_res.json()
    assert len(pull_data["products"]) >= 1
    assert "server_timestamp" in pull_data

    offline_client_id = "offline_order_uuid_9999"
    push_payload = {
        "orders": [
            {
                "line_items": [{"product_id": prod_id, "quantity": 2.0}],
                "discount": 0.0,
                "payment_method": "cash",
                "client_id": offline_client_id
            }
        ],
        "attendance": []
    }

    push_res_1 = await client.post("/api/sync/push", json=push_payload, headers=owner_headers)
    assert push_res_1.status_code == 200
    res_1 = push_res_1.json()["results"][0]
    assert res_1["status"] == "success"
    assert res_1["client_id"] == offline_client_id

    prod_check = await client.get(f"/api/products/{prod_id}", headers=owner_headers)
    assert prod_check.json()["current_stock"] == 3.0

    push_res_2 = await client.post("/api/sync/push", json=push_payload, headers=owner_headers)
    assert push_res_2.status_code == 200
    res_2 = push_res_2.json()["results"][0]
    assert res_2["status"] == "success"

    prod_check_2 = await client.get(f"/api/products/{prod_id}", headers=owner_headers)
    assert prod_check_2.json()["current_stock"] == 3.0

    failed_push = {
        "orders": [
            {
                "line_items": [{"product_id": prod_id, "quantity": 10.0}],
                "discount": 0.0,
                "payment_method": "cash",
                "client_id": "failed_order_123"
            }
        ]
    }
    push_fail_res = await client.post("/api/sync/push", json=failed_push, headers=owner_headers)
    assert push_fail_res.status_code == 200
    res_fail = push_fail_res.json()["results"][0]
    assert res_fail["status"] == "failed"
    assert "Insufficient stock" in res_fail["message"]
