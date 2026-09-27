# ADR-001: Bootstrap remote Terraform state and isolate environment composition

**Status:** Accepted

**Date:** 2026-09-06

## Context

Terraform state maps configuration to AWS resources and can include infrastructure metadata that should not be committed to Git. The platform also needs a layout that lets the same modules serve development first and additional environments later.

## Decision

- Create state resources in `infrastructure/bootstrap` using a one-time local state workflow.
- Store environment state in a versioned, encrypted, non-public S3 bucket.
- Use a DynamoDB table for state locking.
- Keep environment composition in `infrastructure/environments/<environment>` and reusable components in `infrastructure/modules/<module>`.
- Keep account-specific backend and variable files out of Git.

## Consequences

This adds a small bootstrap step and requires careful handling of the first local state file. In exchange, it prevents routine state from living on a workstation or in Git and supports collaboration and CI/CD later. The bootstrap resources should be destroyed last, only after all environment state has been migrated or deliberately removed.
