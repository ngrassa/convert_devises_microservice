import os
from decimal import Decimal
from typing import Any, Dict

import requests
from flask import Flask, jsonify, request

from conversion import convert_amount, parse_amount

app = Flask(__name__)

RATE_SERVICE_URL = os.getenv("RATE_SERVICE_URL", "http://rate_service:5000")


def fetch_rate(base: str, target: str) -> Dict[str, Any]:
    """Call the rate service to retrieve an exchange rate."""
    try:
        response = requests.get(
            f"{RATE_SERVICE_URL}/rate",
            params={"base": base, "target": target},
            timeout=5,
        )
        response.raise_for_status()
        data = response.json()
    except Exception as exc:
        return {"success": False, "error": str(exc)}

    if "rate" not in data:
        return {"success": False, "error": data.get("error", "Taux indisponible")}
    return {"success": True, "rate": Decimal(str(data["rate"]))}


@app.route("/convert", methods=["GET"])
def convert():
    base = request.args.get("base", "USD").upper()
    target = request.args.get("target", "EUR").upper()
    raw_amount = request.args.get("amount", "0")

    try:
        amount = parse_amount(raw_amount)
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400

    rate_result = fetch_rate(base, target)
    if not rate_result["success"]:
        return jsonify({"error": rate_result["error"]}), 502

    converted = convert_amount(amount, rate_result["rate"])
    return jsonify(
        {
            "base": base,
            "target": target,
            "amount": float(amount),
            "rate": float(rate_result["rate"]),
            "converted": float(converted),
        }
    )


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5001")))
