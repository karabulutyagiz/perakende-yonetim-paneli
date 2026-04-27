from datetime import date

from fastapi import APIRouter

from app.api.deps import CurrentTenantId, CurrentTenantUser, DBSession
from app.schemas.report import ReportSummary
from app.services import report_service

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/summary", response_model=ReportSummary)
async def get_summary(
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
    from_date: date | None = None,
    to_date: date | None = None,
) -> ReportSummary:
    return await report_service.build_summary(db, tenant_id, from_date, to_date)
