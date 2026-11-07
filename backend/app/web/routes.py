"""Zero-login hospital web view opened by scanning the patient's QR code (FR-23, FR-24)."""

from pathlib import Path

from fastapi import APIRouter, Depends, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session

from ..core.constants import DISCLAIMER, METRIC_LABELS
from ..core.time import LOCAL_TZ
from ..db.session import get_db
from ..services import triage 

router = APIRouter(include_in_schema=False)
templates = Jinja2Templates(directory=Path(__file__).parent / "templates")


def _local(dt):
    return dt.astimezone(LOCAL_TZ).strftime("%d %b %Y, %I:%M %p")


templates.env.filters["local"] = _local


@router.get("/qr/{token}", response_class=HTMLResponse)
def hospital_summary_page(request: Request, token: str, db: Session = Depends(get_db)):
    try:
        summary = triage.summary(db, token)
    except triage.TokenError as err:
        return templates.TemplateResponse(
            request, "qr_error.html", {"message": err.message}, status_code=err.status_code
        )
    return templates.TemplateResponse(
        request,
        "qr_summary.html",
        {"s": summary, "labels": METRIC_LABELS, "disclaimer": DISCLAIMER},
        headers={"Cache-Control": "no-store", "X-Robots-Tag": "noindex"},
    )
