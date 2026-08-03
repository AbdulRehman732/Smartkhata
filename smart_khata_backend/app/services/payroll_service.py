import uuid
import calendar
from datetime import datetime
from typing import List, Optional, Dict, Any
from app.database import get_database
from app.models.schemas import PayrollRunRequest, utc_now_iso
from app.services.employee_service import get_employees

async def generate_payroll_run(request: PayrollRunRequest) -> Dict[str, Any]:
    db = get_database()
    now = utc_now_iso()
    month_str = request.month # Format: YYYY-MM
    
    try:
        year, month = map(int, month_str.split("-"))
        _, days_in_month = calendar.monthrange(year, month)
    except Exception:
        raise ValueError(f"Invalid month format '{month_str}'. Expected 'YYYY-MM'.")

    employees = await get_employees(active_only=True)
    payroll_lines = []
    total_payout = 0.0

    for emp in employees:
        emp_id = emp["id"]
        # Fetch attendance records for this employee in this month
        regex_pattern = f"^{month_str}-"
        cursor = db["attendance"].find({
            "employee_id": emp_id,
            "date": {"$regex": regex_pattern}
        })
        records = await cursor.to_list(31)

        present_days = sum(1 for r in records if r.get("status") == "present")
        absent_days = sum(1 for r in records if r.get("status") == "absent")
        half_days = sum(1 for r in records if r.get("status") == "half_day")
        leave_days = sum(1 for r in records if r.get("status") == "leave")

        salary_type = emp.get("salary_type", "monthly").lower()
        salary_rate = emp.get("salary_rate", 0.0)

        if salary_type == "monthly":
            # Prorate salary by days actually worked/paid.
            # Leave is PAID (counts as not absent).
            # Absences reduce pay proportionally; half-days count as 0.5 absence deduction.
            absence_deduction_days = absent_days + (0.5 * half_days)
            daily_equivalent = salary_rate / days_in_month if days_in_month > 0 else 0
            calculated_salary = max(0.0, salary_rate - (absence_deduction_days * daily_equivalent))
            days_worked = present_days + leave_days + (0.5 * half_days)
        else: # daily rate
            # Daily-rate staff: paid strictly for days present (full rate) or half-day (half rate).
            # Absent and leave days earn nothing.
            calculated_salary = (present_days * salary_rate) + (half_days * salary_rate * 0.5)
            days_worked = present_days + (0.5 * half_days)

        calculated_salary = round(calculated_salary, 2)
        total_payout += calculated_salary

        payroll_lines.append({
            "employee_id": emp_id,
            "employee_name": emp["name"],
            "salary_type": salary_type,
            "salary_rate": salary_rate,
            "days_worked": days_worked,
            "leave_days": leave_days,
            "absence_days": absent_days,
            "half_days": half_days,
            "calculated_salary": calculated_salary
        })

    payroll_id = str(uuid.uuid4())
    run_doc = {
        "_id": payroll_id,
        "month": month_str,
        "lines": payroll_lines,
        "total_payout": round(total_payout, 2),
        "paid": False,
        "paid_at": None,
        "created_at": now
    }
    await db["payroll_runs"].insert_one(run_doc)
    run_doc["id"] = payroll_id
    return run_doc

async def mark_payroll_run_paid(payroll_id: str) -> Dict[str, Any]:
    db = get_database()
    now = utc_now_iso()
    run = await db["payroll_runs"].find_one({"_id": payroll_id})
    if not run:
        raise ValueError(f"Payroll run with ID '{payroll_id}' not found.")
    
    if run.get("paid"):
        run["id"] = run["_id"]
        return run

    total_payout = run.get("total_payout", 0.0)

    # Log cashbook expense
    if total_payout > 0:
        await db["expenses"].insert_one({
            "_id": str(uuid.uuid4()),
            "category": "salary",
            "amount": total_payout,
            "note": f"Payroll payout for month {run['month']}",
            "date": now
        })

    await db["payroll_runs"].update_one(
        {"_id": payroll_id},
        {"$set": {"paid": True, "paid_at": now}}
    )
    
    run["paid"] = True
    run["paid_at"] = now
    run["id"] = run["_id"]
    return run

async def get_payroll_runs() -> List[Dict[str, Any]]:
    db = get_database()
    cursor = db["payroll_runs"].find({}).sort("created_at", -1)
    runs = await cursor.to_list(100)
    for r in runs:
        r["id"] = r["_id"]
    return runs
