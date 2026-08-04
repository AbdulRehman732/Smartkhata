from fastapi import APIRouter, Depends, Query
from app.auth.dependencies import require_employee_or_owner
from app.services.restock_service import calculate_smart_restock_recommendations

router = APIRouter(prefix="/api/restock", tags=["Smart Restock AI"])

@router.get("/recommendations")
async def get_restock_recommendations(
    lead_time_days: int = Query(3, description="Supplier lead time in days"),
    current_user: dict = Depends(require_employee_or_owner)
):
    """
    Smart Restock AI (#13):
    Generates intelligent reorder quantity suggestions based on lead times and demand velocity.
    """
    return await calculate_smart_restock_recommendations(lead_time_days=lead_time_days)
