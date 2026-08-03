from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import Response
from app.auth.dependencies import require_employee_or_owner
from app.services.pdf_service import generate_order_pdf_bytes

router = APIRouter(prefix="/api/invoice", tags=["PDF Invoices"])

@router.get("/{order_id}/pdf")
async def download_invoice_pdf(
    order_id: str,
    current_user: dict = Depends(require_employee_or_owner)
):
    try:
        pdf_bytes = await generate_order_pdf_bytes(order_id)
        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename=invoice_{order_id[:8]}.pdf"}
        )
    except ValueError as ve:
        raise HTTPException(status_code=404, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
