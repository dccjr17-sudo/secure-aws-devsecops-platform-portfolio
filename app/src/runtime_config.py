"""Optional managed runtime configuration retrieval.

The module never prints a secret value. Local development remains independent
of AWS unless APP_CONFIG_SECRET_ID is explicitly supplied by a future runtime.
"""

import json
import os
from collections.abc import Callable, Mapping
from typing import Any


class RuntimeConfigurationError(RuntimeError):
    """Raised when a configured managed secret is unavailable or malformed."""


SecretValueReader = Callable[..., Mapping[str, Any]]


def load_runtime_configuration(
    secret_id: str | None = None,
    secret_value_reader: SecretValueReader | None = None,
) -> dict[str, Any]:
    """Return JSON configuration from one explicit Secrets Manager secret.

    With no secret ID, local development intentionally uses an empty mapping.
    A configured ID fails closed: it must resolve to a JSON object, but the
    value is never included in an exception, response, or log message.
    """

    configured_secret_id = secret_id or os.getenv("APP_CONFIG_SECRET_ID")
    if not configured_secret_id:
        return {}

    if secret_value_reader is None:
        import boto3

        secret_value_reader = boto3.client("secretsmanager").get_secret_value

    response = secret_value_reader(SecretId=configured_secret_id)
    secret_string = response.get("SecretString")
    if not isinstance(secret_string, str):
        raise RuntimeConfigurationError(
            "Managed runtime configuration must use a string SecretString."
        )

    try:
        configuration = json.loads(secret_string)
    except json.JSONDecodeError as error:
        raise RuntimeConfigurationError(
            "Managed runtime configuration must contain valid JSON."
        ) from error

    if not isinstance(configuration, dict):
        raise RuntimeConfigurationError(
            "Managed runtime configuration must be a JSON object."
        )

    return configuration
