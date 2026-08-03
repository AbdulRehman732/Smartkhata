from typing import List
from fastapi import APIRouter, HTTPException, Depends, Query  # type: ignore
from app.models.schemas import AttendanceMark, AttendanceResponse
from app.auth.dependencies import require_employee_or_owner
from app.services.employee_service import mark_attendance, get_attendance_for_date

router = APIRouter(prefix="/api/attendance", tags=["Attendance"])

@router.post("", response_model=AttendanceResponse)
async def post_attendance(
    data: AttendanceMark,
    current_user: dict = Depends(require_employee_or_owner)
):
    try:
        return await mark_attendance(data)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("", response_model=List[AttendanceResponse])
async def list_attendance(
    date: str = Query(..., description="Date in YYYY-MM-DD format"),
    current_user: dict = Depends(require_employee_or_owner)
):
    return await get_attendance_for_date(date)
