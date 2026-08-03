import pytest  # type: ignore
import pytest_asyncio  # type: ignore
from httpx import AsyncClient, ASGITransport  # type: ignore
from app.main import app
from app.database import set_mock_db, InMemoryDatabase

@pytest.fixture(autouse=True)
def setup_mock_db():
    set_mock_db(True)

@pytest_asyncio.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac

@pytest_asyncio.fixture
async def owner_headers(client: AsyncClient):
    res = await client.post("/api/auth/register", json={
        "username": "owner_test",
        "password": "password123",
        "name": "Owner Store",
        "role": "owner"
    })
    token = res.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

@pytest_asyncio.fixture
async def employee_headers(client: AsyncClient):
    res = await client.post("/api/auth/register", json={
        "username": "emp_test",
        "password": "password123",
        "name": "Employee Store",
        "role": "employee"
    })
    token = res.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
