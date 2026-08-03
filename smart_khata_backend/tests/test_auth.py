import pytest  # type: ignore
from httpx import AsyncClient  # type: ignore

@pytest.mark.asyncio
async def test_auth_register_and_login(client: AsyncClient):
    res = await client.post("/api/auth/register", json={
        "username": "tariq_shop",
        "password": "mypassword123",
        "name": "Tariq Kiryana",
        "role": "owner"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["role"] == "owner"
    assert "access_token" in data

    login_res = await client.post("/api/auth/login", json={
        "username": "tariq_shop",
        "password": "mypassword123"
    })
    assert login_res.status_code == 200
    assert "access_token" in login_res.json()

@pytest.mark.asyncio
async def test_role_based_access_control(client: AsyncClient, owner_headers, employee_headers):
    res_emp = await client.get("/api/payroll", headers=employee_headers)
    assert res_emp.status_code == 403

    res_owner = await client.get("/api/payroll", headers=owner_headers)
    assert res_owner.status_code == 200
