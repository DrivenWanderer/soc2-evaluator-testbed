# Secrets Registry Schema Specification

This document defines the schema and operational rules for `oracle/secrets-registry.json`.

## Purpose

The secrets registry provides an exhaustive inventory of every seeded secret present in the testbed repository. It serves two critical functions:

1. **Redaction Verification:** The evaluator tool must redact all secrets from its findings, reports, and logs. Automated tests compare evaluator output against this registry to ensure zero seeded secrets leak.
2. **Safety & Containment:** The validator script (`scripts/validate-oracle.ps1`) verifies that every committed secret pattern in the repository is recorded here, preventing accidental leaks of real developer credentials.

## Schema Specification (`secrets-registry.json`)

The registry is formatted as JSON adhering to the following structure:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "version": 1,
  "generated": "2026-11-10T12:00:00Z",
  "secrets": [
    {
      "id": "SEC-REG-001",
      "type": "connection-string-password",
      "value": "SyntheticSecretPassword123!",
      "file": "src/ModernApi/appsettings.json",
      "anchor": "Password=",
      "scope": "committed-generic",
      "description": "Hardcoded fake connection string password in ModernApi appsettings"
    }
  ]
}
```

### Property Definitions

- **`version`** (integer, required): Schema version (currently `1`).
- **`generated`** (string, required): ISO-8601 UTC timestamp of generation or update.
- **`secrets`** (array of objects, required):
  - **`id`** (string, required): Unique identifier starting with `SEC-REG-`.
  - **`type`** (string, required): Categorization of the secret (e.g., `connection-string-password`, `generic-api-key`, `jwt-symmetric-key`, `provider-token`).
  - **`value`** (string, required): The exact synthetic secret string.
  - **`file`** (string, required): Path relative to repository root where the secret is seeded.
  - **`anchor`** (string, required): Surrounding text anchor used to locate the value (never line numbers).
  - **`scope`** (string, required):
    - `committed-generic`: Safely committed generic fake secrets.
    - `generated-provider`: Provider-shaped fakes generated dynamically at test-time by `scripts/seed-secrets.ps1` and gitignored.
  - **`description`** (string, optional): Human-readable note explaining the seed purpose.

## Operational Rules

- All secret values must be **fake and non-functional**.
- Provider-pattern fake secrets (AWS, GitHub, Slack tokens) must never be committed; they are generated dynamically into gitignored fixtures by `scripts/seed-secrets.ps1`.
- `scripts/validate-oracle.ps1` cross-validates this registry against `oracle/expected-findings.yml` and the repository files.
