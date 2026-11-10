# Testbed Implementation Progress

## Stage Status Overview

| Stage | Name | Status |
|---|---|---|
| **Stage 0** | **Bootstrap and conventions** | **Completed (PR #1 Merged)** |
| **Stage 1** | **Legacy + Core solutions, secrets, dependencies, debug config, canary** | **Completed** |
| Stage 2 | Code flaws, pipelines, suppressions | Planned (Next) |
| Stage 3 | Runtime behavior, IaC, non-.NET | Planned |
| Stage 4 | Cloud and identity snapshots | Planned (Gated) |
| Stage 5 | Process evidence, org config, history series | Planned |

---

## Stage 1 Task Breakdown & Status

- [x] **Task 1: Configure .NET toolchain and repository global.json**
  - *Deliverable:* Pinned .NET SDK 10.0.404 in `global.json` on branch `stage-1/core-and-legacy-solutions`.
  - *Verification:* `dotnet --version` confirmed 10.0.404; committed as `537a4fa`.
- [x] **Task 2: Scaffold `src/CanaryProject` and register in answer key**
  - *Deliverable:* Project with benign MSBuild execution target writing `artifacts/canary/executed.txt`; added canary to `oracle/expected-findings.yml`.
  - *Verification:* Built project, verified marker file created, verified `validate-oracle.ps1` canary check passed; committed as `6128f76`.
- [x] **Task 3: Scaffold `src/CleanApi` negative control fixture**
  - *Deliverable:* Hardened ASP.NET Core LTS API with parameterized SQL queries, explicit CORS, auth logging, security headers, and `[AllowAnonymous]` negative fixture `TB-N-001`.
  - *Verification:* Built cleanly, `dotnet list package --vulnerable` reported 0 vulnerabilities, `validate-oracle.ps1` negative check passed; committed as `c4f7ece`.
- [x] **Task 4: Implement secret-seeding script `scripts/seed-secrets.ps1`**
  - *Deliverable:* Generator for provider-pattern fake secrets (AWS, GitHub, Slack) into gitignored `fixtures-generated/secrets/` and builder for `oracle/secrets-registry.json`.
  - *Verification:* Executed script, verified registry generated and validated by `validate-oracle.ps1`, verified `-Clean` cleanup; committed as `a0677ce`.
- [x] **Task 5: Scaffold `src/ModernApi` with seeded flaws (SEC-001, DEP-001, CFG-002)**
  - *Deliverable:* Realistic ASP.NET Core LTS API containing connection string password, JWT symmetric key, payment API key, vulnerable `Newtonsoft.Json 12.0.3`, and unconditional `UseDeveloperExceptionPage`.
  - *Verification:* Built cleanly with expected advisory NU1903 (GHSA-5crp-9r3c-p9vr), validated anchors in `validate-oracle.ps1`; committed as `e74d443`.
- [x] **Task 6: Scaffold `src/LegacyPortal` with seeded flaws and legacy solution**
  - *Deliverable:* ASP.NET MVC 5 (.NET Framework 4.8) project in `src/LegacyPortal.sln` with `packages.config` (DEP-001), `web.config` (SEC-001, CFG-002 debug compilation, customErrors off, trace enabled).
  - *Verification:* Validated XML anchors in `validate-oracle.ps1`; committed as `bc5e1e8`.
- [x] **Task 7: Create unified core solution `src/Testbed.sln`**
  - *Deliverable:* Solution binding `ModernApi`, `CleanApi`, and `CanaryProject`.
  - *Verification:* `dotnet build src/Testbed.sln` succeeded with 0 errors; committed as `7a18e18`.
- [x] **Task 8: Finalize Stage 1 flawed answer key and create tag `testbed-stage1-flawed`**
  - *Deliverable:* Complete `oracle/expected-findings.yml` (`repoState: stage1-flawed`) with 11 verified issues, 1 negative, 1 canary. Annotated tag `testbed-stage1-flawed`.
  - *Verification:* `validate-oracle.ps1` passed with 0 errors; committed as `ef822dc`.
- [x] **Task 9: Create variant branch `variant/stage1-remediated`**
  - *Deliverable:* Remediated variant branch branched from `testbed-stage1-flawed`. Remediated 6 issues (`TB-001`, `TB-002`, `TB-003`, `TB-004`, `TB-009`, `TB-010`), left 5 persisting (`TB-005`, `TB-006`, `TB-007`, `TB-008`, `TB-011`), added 1 regression (`TB-012` SEC-001).
  - *Verification:* `dotnet build src/Testbed.sln` succeeded with 0 warnings/errors; `validate-oracle.ps1` passed with 0 errors; committed as `f583539`.
- [x] **Task 10: Complete Stage 1 documentation and exit review**
  - *Deliverable:* `docs/seeded-issues.md`, `docs/limits.md`, updated `docs/decisions.md`, and updated `docs/progress.md`.
  - *Verification:* Full repository build, testbed validation, and git status clean.

---

## Stage 0 Task Breakdown & Status

- [x] **Task 1: Initialize repository skeleton on `main`** (`015ad59`)
- [x] **Task 2: Branch and create empty answer key & schema spec** (`00ed8cb`)
- [x] **Task 3: Implement oracle validator script** (`6b1630e`)
- [x] **Task 4: Add GitHub Actions CI workflow for validation** (`6ea4b45`)
- [x] **Task 5: Finalize documentation and Stage 0 exit review** (`PR #1 Merged`)

---

## Known Issues and Notes

- Legacy ASP.NET MVC 5 project (`src/LegacyPortal`) is maintained as an unbuilt static analysis fixture due to non-elevated host limits preventing Visual Studio Build Tools installation (see `docs/limits.md`).
- Provider-pattern fake secrets are generated only dynamically via `scripts/seed-secrets.ps1` to prevent GitHub push protection triggers.

## Deviations from Plan

- None. All implementations, seed placements, and conventions adhere strictly to `soc2-testbed-plan.md` and approved decisions.

## Where Next Run Starts

- **Stage 2: Code flaws, pipelines, suppressions**
  - Implement SAST flaw seeds: SQL injection (C-001), path traversal (C-002), command injection (C-003), SSRF (C-004), missing auth (C-005), weak cryptography (C-006), insecure deserialization (C-007), CORS wildcard (C-008).
  - Add GitHub Actions CI/CD workflows and mock API response fixtures for pipeline security checks.
  - Add suppression fixtures (valid and invalid) for suppression evaluation.
  - Tag `testbed-stage2-flawed` and update remediated variant branch.