from fastapi import APIRouter

from app.api.v1.endpoints import (
    auth,
    categories,
    customers,
    debts,
    invoices,
    orders,
    products,
    reports,
    sudo,
    ws,
)

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(categories.router)
api_router.include_router(products.router)
api_router.include_router(customers.router)
api_router.include_router(invoices.router)
api_router.include_router(orders.router)
api_router.include_router(debts.router)
api_router.include_router(reports.router)
api_router.include_router(sudo.router)
api_router.include_router(ws.router)
