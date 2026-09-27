# Phase 2 validation — secure containerized application

**Status:** Complete

## Delivered application baseline

- Minimal Python/Flask application with `/` and `/health` endpoints.
- Gunicorn application server listening on non-privileged port 8080.
- Container image built locally through Docker Desktop.
- Dedicated `appuser` runtime identity; the container does not run as `root`.
- Built-in Docker health check and standard-library application tests.

## Validation record

| Check | Result |
| --- | --- |
| Docker image build | Passed |
| Local container startup | Passed |
| `GET /health` response | Passed: `status = ok` |
| Runtime user check | Passed: process ran as `appuser` |
| Application test suite | Passed: 2 tests, 0 failures |

## Security notes and next controls

- No secrets, credentials, or environment-specific configuration are embedded in the source or image build instructions.
- The image uses a maintained Python slim base-image tag for the local baseline. Before a production-like deployment, Phase 3 will record and pin the base-image digest.
- Phase 3 will create a private ECR repository, enable image scanning, and add scoped image-publish permissions.

## Interview-ready summary

> Containerized a Python application for a secure AWS DevSecOps platform, added a health endpoint and automated tests, and hardened the runtime by using a dedicated non-root user and non-privileged port. Validated image build, health, runtime identity, and test execution locally through Docker Desktop.
