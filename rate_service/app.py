import os
from typing import Any, Dict

import requests
from flask import Flask, jsonify, request

app = Flask(__name__)


def fetch_rate(base: str, target: str) -> Dict[str, Any]:
    """Fetch exchange rate from external API."""
    api_url = os.getenv(
        "EXTERNAL_RATE_API",
        "https://api.exchangerate.host/latest",
    )
    symbols = ",".join(sorted({target, "TND"}))
    try:
        response = requests.get(
            api_url,
            params={"base": base, "symbols": symbols},
            timeout=5,
        )
        response.raise_for_status()
        data = response.json()
    except Exception as exc:  # pragma: no cover - network errors are runtime concerns
        return {"success": False, "error": str(exc)}

    rates = data.get("rates") or {}
    sanitized_rates = {
        code: float(value) for code, value in rates.items() if value is not None
    }
    rate = sanitized_rates.get(target)
    if rate is None:
        return {"success": False, "error": f"Taux introuvable pour {target}"}
    return {"success": True, "rate": float(rate), "rates": sanitized_rates}


@app.route("/rate", methods=["GET"])
def get_rate():
    base = request.args.get("base", "USD").upper()
    target = request.args.get("target", "EUR").upper()

    if not base.isalpha() or not target.isalpha():
        return jsonify({"error": "Codes de devise invalides"}), 400

    result = fetch_rate(base, target)
    if not result["success"]:
        return jsonify({"error": result["error"]}), 502

    payload = {
        "base": base,
        "target": target,
        "rate": result["rate"],
    }
    if "rates" in result:
        payload["rates"] = result["rates"]

    return jsonify(payload)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
