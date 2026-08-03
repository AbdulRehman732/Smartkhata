import pytest  # type: ignore
from httpx import AsyncClient  # type: ignore

@pytest.mark.asyncio
async def test_backup_export_and_import(client: AsyncClient, owner_headers):
    await client.post("/api/products", json={
        "name": "Tea Pack 400g",
        "category": "Beverages",
        "unit": "pack",
        "buying_price": 500.0,
        "selling_price": 600.0,
        "current_stock": 20.0
    }, headers=owner_headers)

    export_res = await client.get("/api/backup/export", headers=owner_headers)
    assert export_res.status_code == 200
    data = export_res.json()
    assert "version" in data
    assert len(data["products"]) >= 1

    import_res = await client.post("/api/backup/import", json=data, headers=owner_headers)
    assert import_res.status_code == 200
    assert import_res.json()["status"] == "success"
