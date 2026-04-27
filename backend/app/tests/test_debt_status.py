from datetime import date, timedelta
from decimal import Decimal

import pytest

from app.models.debt import DebtStatus
from app.services.debt_service import compute_status, days_left


@pytest.mark.parametrize(
    "delta_days,expected",
    [
        (15, DebtStatus.GREEN),
        (8, DebtStatus.GREEN),
        (7, DebtStatus.YELLOW),
        (4, DebtStatus.YELLOW),
        (3, DebtStatus.RED),
        (1, DebtStatus.RED),
        (0, DebtStatus.RED),
        (-1, DebtStatus.OVERDUE),
        (-17, DebtStatus.OVERDUE),
    ],
)
def test_compute_status(delta_days: int, expected: DebtStatus) -> None:
    today = date(2026, 4, 14)
    due = today + timedelta(days=delta_days)
    assert compute_status(due, Decimal("100"), today) == expected


def test_paid_overrides_due() -> None:
    today = date(2026, 4, 14)
    due = today - timedelta(days=50)
    assert compute_status(due, Decimal("0"), today) == DebtStatus.PAID


def test_days_left_sign() -> None:
    today = date(2026, 4, 14)
    assert days_left(today + timedelta(days=5), today) == 5
    assert days_left(today - timedelta(days=2), today) == -2
