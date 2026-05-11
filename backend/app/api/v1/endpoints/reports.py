from datetime import date
from uuid import UUID

from fastapi import APIRouter

from app.api.deps import CurrentTenantId, CurrentTenantUser, DBSession
from app.schemas.report import (
    CustomerProductStat,
    ProductCustomerStat,
    ReportSummary,
)
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


@router.get(
    "/products/{product_id}/top-customers",
    response_model=list[ProductCustomerStat],
)
async def product_top_customers(
    product_id: UUID,
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
) -> list[ProductCustomerStat]:
    """Bu ürünü en çok alan müşteriler."""
    return await report_service.top_customers_for_product(db, tenant_id, product_id)


@router.get(
    "/customers/{customer_id}/top-products",
    response_model=list[CustomerProductStat],
)
async def customer_top_products(
    customer_id: UUID,
    db: DBSession,
    tenant_id: CurrentTenantId,
    _: CurrentTenantUser,
) -> list[CustomerProductStat]:
    """Bu müşterinin en çok aldığı ürünler."""
    return await report_service.top_products_for_customer(db, tenant_id, customer_id)
