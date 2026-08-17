import io
import pytest  # type: ignore
from httpx import AsyncClient  # type: ignore

@pytest.mark.asyncio
async def test_ai_intent_classification_and_ledger_mutation(client: AsyncClient, owner_headers):
    await client.post("/api/products", json={
        "name": "Basmati Rice 5kg",
        "urdu_name": "چاول 5 کلو",
        "category": "Grains",
        "unit": "kg",
        "buying_price": 1000.0,
        "selling_price": 1200.0,
        "current_stock": 25.0
    }, headers=owner_headers)

    c_res = await client.post("/api/customers", json={
        "name": "Muhammad Ali",
        "phone": "03119876543"
    }, headers=owner_headers)
    cust_id = c_res.json()["id"]

    await client.post("/api/orders", json={
        "line_items": [{"product_id": (await client.get("/api/products", headers=owner_headers)).json()[0]["id"], "quantity": 1.0}],
        "payment_method": "credit",
        "customer_id": cust_id
    }, headers=owner_headers)

    cust_check = await client.get(f"/api/customers/{cust_id}", headers=owner_headers)
    assert cust_check.json()["balance_due"] == 1200.0

    # 1. Keyword Collision Safeguard Test: "restock" vs "stock"
    res_restock = await client.post("/api/ai/intent", json={"text": "what should I restock list today"}, headers=owner_headers)
    assert res_restock.status_code == 200
    assert res_restock.json()["intent"] == "restock_list"

    # 2. Stock query in Urdu ("chawal ka stock check karo")
    res_stock = await client.post("/api/ai/intent", json={"text": "chawal ka stock check karo"}, headers=owner_headers)
    assert res_stock.status_code == 200
    assert res_stock.json()["intent"] == "check_stock"
    assert "Basmati Rice 5kg" in res_stock.json()["reply"]

    # 3. Customer balance query ("Muhammad Ali ka balance kitna hai")
    res_balance = await client.post("/api/ai/intent", json={"text": "Muhammad Ali ka balance kitna hai"}, headers=owner_headers)
    assert res_balance.status_code == 200
    assert res_balance.json()["intent"] == "customer_balance"

    # 4. VOICE ACTION (Text): Record payment via natural language ("Muhammad Ali ne 500 rupay jamah karwaye")
    res_action = await client.post("/api/ai/intent", json={"text": "Muhammad Ali ne 500 rupay jamah karwaye"}, headers=owner_headers)
    assert res_action.status_code == 200
    assert res_action.json()["intent"] == "record_payment"
    assert "700" in res_action.json()["reply"]

    # Verify Customer Ledger balance updated from 1200.0 -> 700.0
    cust_updated = await client.get(f"/api/customers/{cust_id}", headers=owner_headers)
    assert cust_updated.json()["balance_due"] == 700.0

    # 5. VOICE ACTION (Audio STT): Upload speech audio file -> Converts Speech to Text -> Updates Ledger!
    dummy_wav_header = b"RIFF\x24\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x44\xac\x00\x00\x88\x58\x01\x00\x02\x00\x10\x00data\x00\x00\x00\x00"
    files = {"file": ("voice_ali_payment.wav", io.BytesIO(dummy_wav_header), "audio/wav")}
    
    stt_res = await client.post("/api/ai/stt-intent", files=files, headers=owner_headers)
    assert stt_res.status_code == 200
    assert stt_res.json()["intent"] == "record_payment"
    assert "200" in stt_res.json()["reply"]

    # Verify balance due updated again from 700.0 -> 200.0 via speech audio upload!
    cust_final = await client.get(f"/api/customers/{cust_id}", headers=owner_headers)
    assert cust_final.json()["balance_due"] == 200.0
