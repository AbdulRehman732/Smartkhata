from typing import List
from fastapi import APIRouter, HTTPException, Depends  # type: ignore
from app.models.schemas import PayrollRunRequest, PayrollRunResponse
from app.auth.dependencies import require_owner
from app.services.payroll_service import generate_payroll_run, mark_payroll_run_paid, get_payroll_runs

router = APIRouter(prefix="/api/payroll", tags=["Payroll HR"])

@router.post("/generate", response_model=PayrollRunResponse)
async def generate_payroll(
    data: PayrollRunRequest,
    current_user: dict = Depends(require_owner) # Blocked for employees (403)
):
    try:
        return await generate_payroll_run(data)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("", response_model=List[PayrollRunResponse])
async def list_payroll_runs(
    current_user: dict = Depends(require_owner) # Blocked for employees (403)
):
    return await get_payroll_runs()

@router.post("/{payroll_id}/pay", response_model=PayrollRunResponse)
async def pay_payroll(
    payroll_id: str,
    current_user: dict = Depends(require_owner) # Blocked for employees (403)
):
    try:
        return await mark_payroll_run_paid(payroll_id)
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
