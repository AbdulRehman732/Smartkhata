import io
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from app.services.order_service import get_order_by_id

async def generate_order_pdf_bytes(order_id: str) -> bytes:
    order = await get_order_by_id(order_id)
    if not order:
        raise ValueError(f"Order with ID '{order_id}' not found.")

    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=letter, rightMargin=36, leftMargin=36, topMargin=36, bottomMargin=36)
    styles = getSampleStyleSheet()
    
    title_style = ParagraphStyle(
        'InvoiceTitle',
        parent=styles['Heading1'],
        fontSize=20,
        textColor=colors.HexColor("#1A365D"),
        spaceAfter=12
    )

    subtitle_style = ParagraphStyle(
        'InvoiceSubtitle',
        parent=styles['Normal'],
        fontSize=10,
        textColor=colors.HexColor("#4A5568"),
        spaceAfter=18
    )

    story = []

    # Header
    story.append(Paragraph("<b>SMART KHATA — SALES INVOICE</b>", title_style))
    story.append(Paragraph(f"Order ID: #{order['id']} | Date: {order['created_at'][:19].replace('T', ' ')}", subtitle_style))
    if order.get("customer_name"):
        story.append(Paragraph(f"<b>Customer:</b> {order['customer_name']} (Khata Account)", subtitle_style))
    else:
        story.append(Paragraph("<b>Customer:</b> Walk-in / Cash Customer", subtitle_style))

    story.append(Spacer(1, 12))

    # Table Header
    table_data = [["Item", "Unit Price (Rs.)", "Quantity", "Total (Rs.)"]]
    for item in order.get("line_items", []):
        table_data.append([
            item.get("product_name", "Product"),
            f"{item.get('unit_price', 0.0):.2f}",
            f"{item.get('quantity', 0.0)}",
            f"{item.get('line_total', 0.0):.2f}"
        ])

    table = Table(table_data, colWidths=[240, 100, 80, 100])
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#2B6CB0")),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
        ('BACKGROUND', (0, 1), (-1, -1), colors.HexColor("#F7FAFC")),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
    ]))
    story.append(table)
    story.append(Spacer(1, 18))

    # Summary Breakdown
    summary_data = [
        ["Subtotal:", f"Rs. {order.get('subtotal', 0.0):.2f}"],
        ["Discount:", f"Rs. {order.get('discount', 0.0):.2f}"],
        ["Total Amount:", f"Rs. {order.get('total_amount', 0.0):.2f}"],
        ["Payment Method:", order.get("payment_method", "cash").upper()],
        ["Amount Paid Now:", f"Rs. {order.get('amount_paid_now', 0.0):.2f}"],
        ["Added to Khata:", f"Rs. {order.get('amount_added_to_khata', 0.0):.2f}"]
    ]

    summary_table = Table(summary_data, colWidths=[380, 140])
    summary_table.setStyle(TableStyle([
        ('ALIGN', (0, 0), (-1, -1), 'RIGHT'),
        ('FONTNAME', (0, 2), (-1, 2), 'Helvetica-Bold'),
        ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
        ('TEXTCOLOR', (0, -1), (-1, -1), colors.HexColor("#C53030") if order.get('amount_added_to_khata', 0) > 0 else colors.black),
        ('LINEBELOW', (0, 2), (-1, 2), 1, colors.HexColor("#2B6CB0")),
    ]))
    story.append(summary_table)

    story.append(Spacer(1, 24))
    story.append(Paragraph("<i>Thank you for shopping with Smart Khata!</i>", subtitle_style))

    doc.build(story)
    pdf_bytes = buffer.getvalue()
    buffer.close()
    return pdf_bytes
