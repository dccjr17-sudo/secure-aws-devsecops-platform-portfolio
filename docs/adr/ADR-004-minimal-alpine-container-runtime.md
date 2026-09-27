# ADR-004: Use a minimal Alpine Python runtime for the application image

**Status:** Accepted

**Date:** 2026-09-07

## Context

The first ECR image scan of the Debian-based `python:3.13-slim` runtime reported critical findings in operating-system packages that the Flask workload does not use, including Perl components and the GNU C Library. Several upstream fixes were not yet available in the Debian release used by that image. The initial Docker build also produced an OCI image index, which Amazon ECR Basic Scanning cannot scan.

## Decision

- Use `python:3.13-alpine` as the runtime base image for this small, pure-Python service.
- Build a single Linux/amd64 image manifest for the Basic Scanning validation path.
- Disable build provenance and SBOM attestations in the local and Phase 4 publication paths so ECR Basic Scanning receives a compatible single-platform manifest. Revisit independent provenance when Phase 5 adds broader supply-chain controls.
- Continue to run the health check and unit tests after each base-image change.

## Consequences

The Alpine runtime removes unused Debian packages and reduces the container footprint. Alpine uses musl instead of glibc, so a future dependency that requires native extensions must be tested before adoption. Image scanning is a recurring control: each new immutable image tag is scanned, and critical findings must be remediated or explicitly documented before promotion.
