import pytest
from decimal import Decimal

from convert_service import conversion


def test_parse_amount_valid():
    assert conversion.parse_amount("10.50") == Decimal("10.50")
    assert conversion.parse_amount("0") == Decimal("0")


@pytest.mark.parametrize("raw", ["abc", "", "10.5.2"])
def test_parse_amount_invalid_input(raw):
    with pytest.raises(ValueError):
        conversion.parse_amount(raw)


def test_parse_amount_negative():
    with pytest.raises(ValueError):
        conversion.parse_amount("-1")


def test_convert_amount_rounding():
    amount = Decimal("10")
    rate = Decimal("1.3333")
    assert conversion.convert_amount(amount, rate) == Decimal("13.33")


def test_convert_amount_zero():
    assert conversion.convert_amount(Decimal("0"), Decimal("5")) == Decimal("0.00")
