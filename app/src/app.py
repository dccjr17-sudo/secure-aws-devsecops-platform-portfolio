"""Minimal workload for the Secure AWS DevSecOps Application Platform."""

from collections.abc import Callable
from typing import Any

from flask import Flask, jsonify

from src.runtime_config import load_runtime_configuration


def create_app(
    configuration_loader: Callable[[], dict[str, Any]] = load_runtime_configuration,
) -> Flask:
    """Create and configure the application instance."""
    app = Flask(__name__)
    runtime_configuration = configuration_loader()
    configured_message = runtime_configuration.get("application_message")
    application_message = (
        configured_message
        if isinstance(configured_message, str) and configured_message.strip()
        else "Application is running."
    )

    # This Phase 6 demonstration exposes only the intentionally harmless
    # message field. The complete managed configuration is never retained in
    # Flask's public-facing configuration object, returned, or logged.

    @app.get("/")
    def index():
        return jsonify(
            application="secure-aws-devsecops-platform",
            message=application_message,
        )

    @app.get("/health")
    def health():
        return jsonify(status="ok")

    return app
