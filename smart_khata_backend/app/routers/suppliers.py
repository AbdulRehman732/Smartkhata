from typing import List
from fastapi import APIRouter, HTTPException, Depends # type: ignore
from app.models.schemas import SupplierCreate, SupplierResponse, PurchaseOrderCreate
from app.auth.dependencies import require_employee_or_owner
from app.services.inventory_service import (
    create_supplier, get_suppliers, get_supplier_by_id, create_purchase_order
)

router = APIRouter(prefix="/api/suppliers", tags=["Suppliers"])

@router.post("", response_model=SupplierResponse)
async def add_supplier(
    data: SupplierCreate,
    current_user: dict = Depends(require_employee_or_owner)
):
    return await create_supplier(data)

@router.get("", response_model=List[SupplierResponse])
async def list_suppliers(
    current_user: dict = Depends(require_employee_or_owner)
):
    return await get_suppliers()

@router.get("/{supplier_id}", response_model=SupplierResponse)
async def get_supplier(
    supplier_id: str,
    current_user: dict = Depends(require_employee_or_owner)
):
    sup = await get_supplier_by_id(supplier_id)
    if not sup:
        raise HTTPException(status_code=404, detail="Supplier not found.")
    return sup

@router.post("/purchase-orders")
async def add_purchase_order(
    po_data: PurchaseOrderCreate,
    current_user: dict = Depends(require_employee_or_owner)
):
    try:
        return await create_purchase_order(po_data)
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
