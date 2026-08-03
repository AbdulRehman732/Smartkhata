from typing import List
from fastapi import APIRouter, HTTPException, Depends  # type: ignore
from app.models.schemas import OrderCreate, OrderResponse
from app.auth.dependencies import require_employee_or_owner
from app.services.order_service import create_order, get_orders, get_order_by_id

router = APIRouter(prefix="/api/orders", tags=["Orders & POS"])

@router.post("", response_model=OrderResponse)
async def new_order(
    data: OrderCreate,
    current_user: dict = Depends(require_employee_or_owner)
):
    try:
        return await create_order(data)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("", response_model=List[OrderResponse])
async def list_orders(
    current_user: dict = Depends(require_employee_or_owner)
):
    return await get_orders()

@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: str,
    current_user: dict = Depends(require_employee_or_owner)
):
    order = await get_order_by_id(order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found.")
    return order
