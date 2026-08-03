from fastapi import APIRouter, Depends
from app.models.schemas import ForecastResponse
from app.auth.dependencies import require_employee_or_owner
from app.services.forecast_service import generate_demand_forecast

router = APIRouter(prefix="/api/forecast", tags=["Restock Demand Forecasting"])

@router.get("", response_model=ForecastResponse)
async def get_forecast(
    current_user: dict = Depends(require_employee_or_owner)
):
    return await generate_demand_forecast()
