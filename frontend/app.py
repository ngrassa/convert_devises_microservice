import os

import requests
from flask import Flask, jsonify, render_template, request

app = Flask(__name__)

CONVERTER_URL = os.getenv("CONVERTER_URL", "http://convert_service:5001")


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")


@app.route("/convert", methods=["POST"])
def proxy_convert():
    payload = {
        "base": request.form.get("base", "USD"),
        "target": request.form.get("target", "EUR"),
        "amount": request.form.get("amount", "0"),
    }
    try:
        response = requests.get(f"{CONVERTER_URL}/convert", params=payload, timeout=5)
        response.raise_for_status()
    except Exception as exc:
        return jsonify({"error": str(exc)}), 502
    return jsonify(response.json())


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
