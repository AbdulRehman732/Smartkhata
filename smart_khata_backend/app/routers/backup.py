from typing import Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Body
from app.models.schemas import BackupExportData
from app.auth.dependencies import require_owner
from app.services.backup_service import generate_full_backup, restore_from_backup

router = APIRouter(prefix="/api/backup", tags=["Local Backup & File Export"])

@router.get("/export", response_model=BackupExportData)
async def export_backup(
    current_user: dict = Depends(require_owner)
):
    return await generate_full_backup()

@router.post("/import")
async def import_backup(
    backup_data: Dict[str, Any] = Body(...),
    current_user: dict = Depends(require_owner)
):
    try:
        return await restore_from_backup(backup_data)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid backup file format: {str(e)}")
