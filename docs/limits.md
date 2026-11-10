# Testbed Known Limits and Environment Constraints

This document records deliberate trade-offs, host environment constraints, and scanner-relevant limitations in `soc2-evaluator-testbed`.

---

## 1. Legacy .NET Framework Build and Runtime Limits

- **Constraint:** The development host environment runs non-elevated (standard user privileges). Installing Visual Studio Build Tools 2022 and the .NET Framework 4.8 targeting pack requires administrative privileges (installer exit code 1602).
- **Impact on `src/LegacyPortal`:**
  - `src/LegacyPortal` is scaffolded as a realistic, well-formed ASP.NET MVC 5 (.NET Framework 4.8) solution with `src/LegacyPortal.sln`, `LegacyPortal.csproj`, `packages.config`, and `web.config`.
  - The project is **not compiled** locally during testbed builds (`dotnet build src/Testbed.sln` includes `ModernApi`, `CleanApi`, and `CanaryProject`, leaving `src/LegacyPortal.sln` standalone).
  - Runtime verification with IIS Express was not performed.
- **Coverage & Verification:**
  - All seeded flaws in `LegacyPortal` (`TB-007` DEP-001 in `packages.config`, `TB-008` SEC-001 in `web.config`, `TB-009` CFG-002 debug compilation, `TB-010` CFG-002 customErrors off, `TB-011` CFG-002 trace enabled) are static file/config patterns detectable by file-based scanners.
  - Text anchors and presence are strictly validated by `scripts/validate-oracle.ps1`.
  - In `oracle/expected-findings.yml`, `detection` for `TB-007` is set to `best-effort` reflecting the unbuilt packages.config format.

---

## 2. GitHub Public Repository Security Defaults

- **Constraint:** Decision D4 / CICD-002: GitHub automatically enables and enforces Secret Scanning on all public repositories, preventing an operator from disabling Secret Scanning in live repository settings.
- **Impact on CICD-002 ("Secret scanning not enabled"):**
  - Live GitHub API checks against `DrivenWanderer/soc2-evaluator-testbed` will always return secret scanning enabled.
  - To test negative evaluation and detection of disabled secret scanning, Stage 2 introduces recorded GitHub API response fixture mocks simulating an organization/repo with secret scanning disabled.

---

## 3. Synthetic Secrets and Secret Scanner Push Protection

- **Constraint:** Decision D2: Committing well-known provider-pattern tokens (such as AWS access key ID `AKIA...`, GitHub personal access token `ghp_...`, or Slack bot token `xoxb-...`) triggers GitHub Push Protection and provider token revocation hooks.
- **Strategy & Limits:**
  - Only generic-pattern synthetic credentials (SQL connection string passwords, JWT symmetric keys, arbitrary API keys) are committed to git.
  - Provider-pattern fake tokens are generated on-demand at test time via `scripts/seed-secrets.ps1` into `fixtures-generated/secrets/` and indexed in `oracle/secrets-registry.json` (both gitignored).
  - Offline scanners scanning repository checkouts must run `seed-secrets.ps1` beforehand if testing provider token pattern detection.

---

## 4. Advisory Feeds and Vulnerability Scanners (DEP-001)

- **Constraint:** Vulnerability advisory databases (GitHub Advisory Database, NVD, OSV) evolve over time.
- **Current State:**
  - `Newtonsoft.Json 12.0.3` was verified on 2026-11-10 via .NET 10 SDK package audit (`dotnet list package --vulnerable`) to have a High severity advisory (`GHSA-5crp-9r3c-p9vr` / `CVE-2024-38063` / build warning `NU1903`).
  - If scanning tools use different advisory databases or severity mapping criteria, severity ratings may fluctuate between High and Moderate.

---

## 5. Shell and Host OS Specifics

- **Constraint:** Development and CI execution assume PowerShell (PowerShell 7 Core or Windows PowerShell 5.1).
- **Line Endings:** Git repository is configured with standard LF / CRLF handling. String anchor checks in `scripts/validate-oracle.ps1` perform trimmed line and substring matching to remain resilient across CRLF and LF checkouts.