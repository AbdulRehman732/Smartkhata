from typing import Optional
from fastapi import APIRouter, Depends, Query
from app.models.schemas import SyncPullResponse, SyncPushPayload, SyncPushResponse
from app.auth.dependencies import require_employee_or_owner
from app.services.sync_service import pull_catalogue_changes, push_offline_batch

router = APIRouter(prefix="/api/sync", tags=["Offline Synchronization"])

@router.get("/pull", response_model=SyncPullResponse)
async def pull_sync(
    since_timestamp: Optional[str] = Query(None, description="ISO timestamp of last sync"),
    current_user: dict = Depends(require_employee_or_owner)
):
    return await pull_catalogue_changes(since_timestamp)

@router.post("/push", response_model=SyncPushResponse)
async def push_sync(
    payload: SyncPushPayload,
    current_user: dict = Depends(require_employee_or_owner)
):
    return await push_offline_batch(payload)
