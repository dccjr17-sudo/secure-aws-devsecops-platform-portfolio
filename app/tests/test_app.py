"""Tests for the minimal application health endpoints."""

import os
import unittest
from unittest.mock import Mock, patch

from src.app import create_app
from src.runtime_config import RuntimeConfigurationError, load_runtime_configuration


class ApplicationTestCase(unittest.TestCase):
    def setUp(self):
        self.client = create_app().test_client()

    def test_health_endpoint_reports_ok(self):
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), {"status": "ok"})

    def test_index_identifies_the_platform(self):
        response = self.client.get("/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.get_json()["application"], "secure-aws-devsecops-platform"
        )

    def test_managed_configuration_can_set_the_non_sensitive_landing_message(self):
        client = create_app(
            configuration_loader=lambda: {"application_message": "Managed config loaded."}
        ).test_client()

        response = client.get("/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["message"], "Managed config loaded.")


class RuntimeConfigurationTestCase(unittest.TestCase):
    def test_local_development_does_not_require_aws_or_a_secret(self):
        with patch.dict(os.environ, {}, clear=True):
            configuration = load_runtime_configuration()

        self.assertEqual(configuration, {})

    def test_reader_receives_only_the_explicit_secret_id(self):
        secret_value_reader = Mock(
            return_value={"SecretString": '{"application_message": "Managed config loaded."}'}
        )

        configuration = load_runtime_configuration(
            secret_id="example/application-configuration",
            secret_value_reader=secret_value_reader,
        )

        self.assertEqual(configuration["application_message"], "Managed config loaded.")
        secret_value_reader.assert_called_once_with(
            SecretId="example/application-configuration"
        )

    def test_malformed_managed_configuration_fails_without_revealing_its_value(self):
        with self.assertRaisesRegex(
            RuntimeConfigurationError, "must contain valid JSON"
        ) as context:
            load_runtime_configuration(
                secret_id="example/application-configuration",
                secret_value_reader=Mock(return_value={"SecretString": "not json"}),
            )

        self.assertNotIn("not json", str(context.exception))
