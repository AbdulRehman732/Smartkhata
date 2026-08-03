import pytest  # type: ignore
from httpx import AsyncClient  # type: ignore

@pytest.mark.asyncio
async def test_pdf_invoice_generation(client: AsyncClient, owner_headers):
    # Setup product
    p_res = await client.post("/api/products", json={
        "name": "Tea Pack 400g",
        "category": "Beverages",
        "unit": "pack",
        "buying_price": 500.0,
        "selling_price": 600.0,
        "current_stock": 20.0
    }, headers=owner_headers)
    prod_id = p_res.json()["id"]

    # Create order
    order_res = await client.post("/api/orders", json={
        "line_items": [{"product_id": prod_id, "quantity": 2.0}],
        "discount": 50.0,
        "payment_method": "cash"
    }, headers=owner_headers)
    order_id = order_res.json()["id"]

    # Request PDF invoice
    pdf_res = await client.get(f"/api/invoice/{order_id}/pdf", headers=owner_headers)
    assert pdf_res.status_code == 200
    assert pdf_res.headers["content-type"] == "application/pdf"
    assert pdf_res.content.startswith(b"%PDF")
