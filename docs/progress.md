# Testbed Implementation Progress

## Stage Status Overview

| Stage | Name | Status |
|---|---|---|
| **Stage 0** | **Bootstrap and conventions** | **Completed (Ready for Review)** |
| Stage 1 | Legacy + Core solutions, secrets, dependencies, debug config, canary | Planned (Next) |
| Stage 2 | Code flaws, pipelines, suppressions | Planned |
| Stage 3 | Runtime behavior, IaC, non-.NET | Planned |
| Stage 4 | Cloud and identity snapshots | Planned (Gated) |
| Stage 5 | Process evidence, org config, history series | Planned |

---

## Stage 0 Task Breakdown & Status

- [x] **Task 1: Initialize repository skeleton on `main`**
  - *Deliverable:* Git repo with safety-first `README.md`, `.gitignore`, `docs/plan.md`, `LICENSE`.
  - *Verification:* Root commit created on `main` (`015ad59`).
- [x] **Task 2: Branch and create empty answer key (`oracle/expected-findings.yml`) & schema spec**
  - *Deliverable:* Feature branch `stage-0/bootstrap-and-conventions` with `oracle/expected-findings.yml` schema v1 and `oracle/secrets-registry.schema.md`.
  - *Verification:* Validated YAML parsing and property existence; committed as `00ed8cb`.
- [x] **Task 3: Implement oracle validator script (`scripts/validate-oracle.ps1`)**
  - *Deliverable:* Pure-PowerShell validator script checking schema, anchors, files, secret registry, and credential leak patterns.
  - *Verification:* Local execution against empty answer key returned exit code 0; committed as `6b1630e`.
- [x] **Task 4: Add GitHub Actions CI workflow for validation (`.github/workflows/validate-oracle.yml`)**
  - *Deliverable:* CI workflow running on push to `main` and `stage-*/**` branches and PRs.
  - *Verification:* Script execution tested locally; committed as `6ea4b45`.
- [x] **Task 5: Finalize documentation and Stage 0 exit review**
  - *Deliverable:* `docs/progress.md` and `docs/decisions.md` capturing full Stage 0 history and exit checklist.
  - *Verification:* Self-review against Definition of Done checklist.

---

## Known Issues and Notes

- Neither .NET SDK nor Visual Studio Build Tools are currently installed on the host machine (only .NET runtimes 5.0, 6.0, 10.0 are present). Installing the approved .NET SDK and .NET Framework 4.8 targeting pack will be requested as part of Stage 1 preparation.
- Node.js and Python are not installed on the system; this will be addressed in Stage 3 according to D5.

## Deviations from Plan

- None. All tasks and conventions adhere strictly to `soc2-testbed-plan.md` and the approved decisions.

## Where Next Run Starts

- **Stage 1:** Foundations for tool Phases 0 and 1.
  - Request approval to install required .NET SDK and build tools (D3).
  - Scaffold `src/LegacyPortal`, `src/ModernApi`, `src/CleanApi`, and `src/CanaryProject`.
  - Implement `scripts/seed-secrets.ps1` and `oracle/secrets-registry.json`.
  - Seed SEC-001, DEP-001, CFG-002; generate answer keys for flawed state and remediated variant branch.
