import pytest  # type: ignore
from httpx import AsyncClient  # type: ignore

@pytest.mark.asyncio
async def test_payroll_calculation_and_expense_logging(client: AsyncClient, owner_headers):
    emp_m = await client.post("/api/employees", json={
        "name": "Kamran Monthly",
        "role_title": "Store Helper",
        "salary_type": "monthly",
        "salary_rate": 30000.0,
        "phone": "03001112233"
    }, headers=owner_headers)
    emp_m_id = emp_m.json()["id"]

    emp_d = await client.post("/api/employees", json={
        "name": "Zahid Daily",
        "role_title": "Loader",
        "salary_type": "daily",
        "salary_rate": 1000.0,
        "phone": "03004445566"
    }, headers=owner_headers)
    emp_d_id = emp_d.json()["id"]

    target_month = "2026-06"

    await client.post("/api/attendance", json={"employee_id": emp_m_id, "date": "2026-06-01", "status": "absent"}, headers=owner_headers)
    await client.post("/api/attendance", json={"employee_id": emp_m_id, "date": "2026-06-02", "status": "absent"}, headers=owner_headers)
    await client.post("/api/attendance", json={"employee_id": emp_m_id, "date": "2026-06-03", "status": "half_day"}, headers=owner_headers)
    await client.post("/api/attendance", json={"employee_id": emp_m_id, "date": "2026-06-04", "status": "leave"}, headers=owner_headers)
    await client.post("/api/attendance", json={"employee_id": emp_m_id, "date": "2026-06-05", "status": "leave"}, headers=owner_headers)

    for d in range(1, 6):
        await client.post("/api/attendance", json={"employee_id": emp_d_id, "date": f"2026-06-0{d}", "status": "present"}, headers=owner_headers)
    await client.post("/api/attendance", json={"employee_id": emp_d_id, "date": "2026-06-06", "status": "half_day"}, headers=owner_headers)
    await client.post("/api/attendance", json={"employee_id": emp_d_id, "date": "2026-06-07", "status": "half_day"}, headers=owner_headers)
    await client.post("/api/attendance", json={"employee_id": emp_d_id, "date": "2026-06-08", "status": "leave"}, headers=owner_headers)
    await client.post("/api/attendance", json={"employee_id": emp_d_id, "date": "2026-06-09", "status": "absent"}, headers=owner_headers)

    gen_res = await client.post("/api/payroll/generate", json={"month": target_month}, headers=owner_headers)
    assert gen_res.status_code == 200
    run_data = gen_res.json()
    payroll_id = run_data["id"]

    lines = {l["employee_name"]: l["calculated_salary"] for l in run_data["lines"]}
    assert lines["Kamran Monthly"] == 27500.0
    assert lines["Zahid Daily"] == 6000.0
    assert run_data["total_payout"] == 33500.0

    pay_res = await client.post(f"/api/payroll/{payroll_id}/pay", headers=owner_headers)
    assert pay_res.status_code == 200
    assert pay_res.json()["paid"] is True

    ledger_res = await client.get("/api/cashbook/ledger", headers=owner_headers)
    assert ledger_res.status_code == 200
    ledger = ledger_res.json()
    salary_expenses = [e for e in ledger["entries"] if e["category"] == "salary"]
    assert len(salary_expenses) >= 1
    assert salary_expenses[0]["amount"] == 33500.0
