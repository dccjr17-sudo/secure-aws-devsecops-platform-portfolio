# Security policy for this private lab

Do not place credentials, access tokens, private keys, personal data, account IDs, screenshots of sensitive AWS console views, or employer/customer/government information in this repository.

If a secret is ever committed, treat it as exposed: revoke or rotate it immediately, remove it from Git history, and document the remediation privately. Do not rely on deleting a file in a later commit.

Security controls for the platform are added phase by phase and documented in [docs/security/threat-model.md](docs/security/threat-model.md).
