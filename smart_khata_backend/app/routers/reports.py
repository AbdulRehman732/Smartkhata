from fastapi import APIRouter, HTTPException, Depends, Query
from app.models.schemas import DashboardResponse, FinancialReportResponse
from app.auth.dependencies import require_owner, require_employee_or_owner
from app.services.cashbook_service import get_dashboard_metrics, get_financial_summary

router = APIRouter(prefix="/api/reports", tags=["Financial Reports & Dashboard"])

@router.get("/dashboard", response_model=DashboardResponse)
async def get_dashboard(
    current_user: dict = Depends(require_employee_or_owner)
):
    return await get_dashboard_metrics()

@router.get("/summary", response_model=FinancialReportResponse)
async def get_summary_report(
    start_date: str = Query(..., description="YYYY-MM-DD"),
    end_date: str = Query(..., description="YYYY-MM-DD"),
    current_user: dict = Depends(require_owner) # Blocked for employees (403)
):
    return await get_financial_summary(start_date, end_date)
