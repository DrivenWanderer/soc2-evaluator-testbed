# Testbed Decisions Log

This log records every architectural decision, tool/dependency approval, and convention established for `soc2-evaluator-testbed`.

---

## 2026-11-10: Bootstrap Decisions (Stage 0)

### Decision D1: Repository Name and Visibility
- **Question:** What is the repository name, description, and visibility under GitHub account `DrivenWanderer`?
- **Options Considered:**
  - Option A: Name `soc2-evaluator-testbed`, description *"Intentionally vulnerable testbed application and fixtures for SOC 2 evaluator tooling (TESTING ONLY - DO NOT DEPLOY)"*, public repository.
  - Option B: Custom alternate name or private visibility.
- **Owner's Decision:** Option A approved.
- **Action Taken:** Created local git repository `soc2-evaluator-testbed` with public conventions and prominent safety warnings.

### Decision: Repository License
- **Question:** What open-source license governs the testbed repository?
- **Options Considered:**
  - Option A: MIT License (matching `soc2-evaluator`).
  - Option B: Apache 2.0.
  - Option C: No license file.
- **Owner's Decision:** Option A approved.
- **Action Taken:** Added `LICENSE` with standard MIT terms matching the evaluator project.

### Decision D2: Secret-Seeding Strategy
- **Question:** How should synthetic credentials be seeded without triggering GitHub push protection blocks?
- **Options Considered:**
  - Option A: Commit only generic-pattern fake secrets (connection string passwords, generic API keys); generate provider-pattern fakes (AWS, GitHub, Slack tokens) dynamically at test time via a gitignored script (`seed-secrets.ps1`).
  - Option B: Commit everything and rely on push-protection bypass.
  - Option C: Generic secrets only.
- **Owner's Decision:** Option A (default) approved.
- **Action Taken:** Established `oracle/secrets-registry.schema.md` with `committed-generic` and `generated-provider` scopes; added `oracle/secrets-registry.json` to `.gitignore`.

### Decision D3: Legacy .NET Framework Build Toolchain
- **Question:** How should the legacy ASP.NET MVC 5 (.NET Framework 4.8) project in `src/LegacyPortal` be built and verified?
- **Options Considered:**
  - Option A: Install VS Build Tools / MSBuild and .NET Framework 4.8 targeting pack plus IIS Express to allow real compilation and runtime verification for Spike A.
  - Option B: Create the project unbuilt and record runtime checks as not verified.
- **Owner's Decision:** Option A (default) approved.
- **Action Taken:** Planned for installation approval in Stage 1. Also noted that a .NET SDK will need to be approved and installed prior to building ModernApi.

### Decision D4: CICD-002 Secret Scanning Disabled Gap
- **Question:** How should the "secret scanning not enabled" check be tested given GitHub enforces secret scanning on all public repositories?
- **Options Considered:**
  - Option A: Provide recorded GitHub API response fixtures with secret scanning reported as disabled, plus document the public repo limitation in `docs/limits.md`.
  - Option B: Create a secondary private companion repository.
  - Option C: Accept the coverage gap without fixtures.
- **Owner's Decision:** Option A (default) approved.
- **Action Taken:** Scheduled recorded API response fixtures for Stage 2.

### Decision D5: Non-.NET Language Scope
- **Question:** What non-.NET language services should be included in the testbed?
- **Options Considered:**
  - Option A: Include Node.js services (`node-service` with lockfile, `node-service-nolock` without lockfile); Python service optional; Java excluded.
  - Option B: Include Java / Python / Go.
- **Owner's Decision:** Option A (default) approved.
- **Action Taken:** Scoped `services/node-service` and `services/node-service-nolock` for Stage 3.

### Decision D6: Cloud and Identity Fixtures (Stage 4)
- **Question:** How should cloud and IdP posture be exercised?
- **Options Considered:**
  - Option A: Recorded JSON snapshots conforming to the evaluator's Phase 4 collector contract, plus a matching drift pair.
  - Option B: Live sandbox cloud tenant.
- **Owner's Decision:** Option A (default) approved.
- **Action Taken:** Deferred to Stage 4, gated on evaluator collector contract design.

### Decision D7: Git Branching and Merge Strategy
- **Question:** What git merge strategy preserves tagged commits and provenance on `main`?
- **Options Considered:**
  - Option A: Standard merge commits (`git merge --no-ff`); squash merges prohibited.
  - Option B: Squash merges.
- **Owner's Decision:** Option A (default) approved.
- **Action Taken:** Enforced non-fast-forward merge commit protocol for all feature branches into `main`.


## 2026-11-10: Stage 1 Implementation Decisions

### Decision: .NET SDK Version and Tooling Installation
- **Question:** Which .NET SDK should be installed on the development host for `ModernApi`, `CleanApi`, and `CanaryProject`?
- **Context:** The development host lacked a pre-installed .NET SDK. Non-elevated execution prevented `winget` installation.
- **Resolution:** Downloaded and executed official `dotnet-install.ps1` to install .NET SDK 10.0.404 to user profile `C:\Users\perki\AppData\Local\Microsoft\dotnet`. Configured `global.json` pinning SDK version `10.0.404`.

### Decision D3 Resolution: Legacy ASP.NET MVC 5 Build Toolchain
- **Question:** How to proceed when Visual Studio Build Tools 2022 cannot be installed without elevation?
- **Context:** Visual Studio Build Tools installer returned exit code 1602 (elevation required).
- **Resolution:** Invoked the plan section 11 legacy fallback protocol: scaffolded `src/LegacyPortal` as an unbuilt static solution (`src/LegacyPortal.sln`, `LegacyPortal.csproj`, `packages.config`, `web.config`) targeting .NET Framework 4.8. All seeded flaws are verified via anchor validation in `scripts/validate-oracle.ps1`. Documented the constraint in `docs/limits.md`.

### Decision: Pinned Vulnerable Dependency for DEP-001
- **Question:** Which vulnerable package version should be pinned for DEP-001?
- **Candidate Evaluated:** `Newtonsoft.Json 12.0.3` (MIT license).
- **Verification:** Verified with `dotnet list package --vulnerable --include-transitive` which reported High severity advisory `GHSA-5crp-9r3c-p9vr` (CVE-2024-38063) producing build warning `NU1903`.
- **Resolution:** Pinned `Newtonsoft.Json 12.0.3` in `src/ModernApi/ModernApi.csproj` and `src/LegacyPortal/packages.config`.