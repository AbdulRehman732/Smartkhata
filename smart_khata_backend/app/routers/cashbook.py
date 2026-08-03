from typing import List, Optional
from fastapi import APIRouter, HTTPException, Depends, Query
from app.models.schemas import ExpenseCreate, ExpenseResponse, CashBookLedgerResponse
from app.auth.dependencies import require_owner
from app.services.cashbook_service import create_expense, get_expenses, get_cashbook_ledger

router = APIRouter(prefix="/api/cashbook", tags=["CashBook & Expenses"])

@router.post("/expenses", response_model=ExpenseResponse)
async def add_expense(
    data: ExpenseCreate,
    current_user: dict = Depends(require_owner) # Blocked for employees (403)
):
    return await create_expense(data)

@router.get("/expenses", response_model=List[ExpenseResponse])
async def list_expenses(
    category: Optional[str] = Query(None),
    current_user: dict = Depends(require_owner) # Blocked for employees (403)
):
    return await get_expenses(category=category)

@router.get("/ledger", response_model=CashBookLedgerResponse)
async def view_ledger(
    current_user: dict = Depends(require_owner) # Blocked for employees (403)
):
    return await get_cashbook_ledger()
