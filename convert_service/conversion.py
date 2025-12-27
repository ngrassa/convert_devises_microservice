from decimal import Decimal, InvalidOperation, ROUND_HALF_UP


def parse_amount(raw_amount: str) -> Decimal:
    """Convert user input to Decimal and validate it is non-negative."""
    try:
        amount = Decimal(raw_amount)
    except (InvalidOperation, ValueError) as exc:
        raise ValueError("Le montant doit être un nombre") from exc

    if amount < 0:
        raise ValueError("Le montant doit être positif ou nul")
    return amount


def convert_amount(amount: Decimal, rate: Decimal) -> Decimal:
    """Convert the amount using the given rate with 2 decimal rounding."""
    return (amount * rate).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
