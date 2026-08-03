from typing import List
from fastapi import APIRouter, HTTPException, Depends # type: ignore
from app.models.schemas import EmployeeCreate, EmployeeResponse
from app.auth.dependencies import require_owner
from app.services.employee_service import create_employee, get_employees, get_employee_by_id

router = APIRouter(prefix="/api/employees", tags=["Employee HR"])

@router.post("", response_model=EmployeeResponse)
async def add_employee(
    data: EmployeeCreate,
    current_user: dict = Depends(require_owner) # Blocked for employees (403)
):
    try:
        return await create_employee(data)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("", response_model=List[EmployeeResponse])
async def list_employees(
    current_user: dict = Depends(require_owner) # Blocked for employees (403)
):
    return await get_employees()

@router.get("/{employee_id}", response_model=EmployeeResponse)
async def get_employee(
    employee_id: str,
    current_user: dict = Depends(require_owner) # Blocked for employees (403)
):
    emp = await get_employee_by_id(employee_id)
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found.")
    return emp
