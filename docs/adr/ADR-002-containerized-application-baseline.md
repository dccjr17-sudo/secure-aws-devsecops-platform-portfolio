# ADR-002: Start with a minimal non-root containerized application

**Status:** Accepted

**Date:** 2026-09-06

## Context

The platform needs a real workload to demonstrate image building, registry access, CI/CD, secrets, security scanning, logging, and eventually Kubernetes. The application should be small enough that infrastructure and security decisions remain the focus.

## Decision

- Use a small Python/Flask application with `/` and `/health` endpoints.
- Run it through Gunicorn in a Linux container.
- Use port 8080 and run the process as a dedicated non-root user.
- Keep application configuration and secrets out of image layers and source control.
- Use standard-library `unittest` tests so tests can run inside the application image without a separate development image at this stage.

## Consequences

The application is intentionally simple and is not presented as a product feature. It gives every later phase a stable workload and makes the security controls visible: container user, health checking, ECR permissions, scan gates, runtime configuration, observability, and Kubernetes policies.
