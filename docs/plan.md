# SOC 2 Evaluator Testbed: Purpose-Built Flawed Site (Plan v1)

Companion to `docs/plan.md` (SOC 2 Evaluator Decisions and Implementation Plan, v2). That plan needs real test targets for its spikes, check catalog, probe, IaC, cloud, and process-evidence features. This plan defines a small, **intentionally flawed** site and supporting fixtures that exercise every check in that catalog, plus an **answer key** so tool output can be verified automatically.

---

## 1. Purpose and Design Principles

1. **Ground truth first.** Every seeded flaw is recorded in a machine-readable answer key (`expected-findings.yml`). A tool run is "correct" when it matches the key, not when it looks plausible.
2. **Negatives matter as much as positives.** The repo includes clean reference code and deliberate false-positive traps, so false-positive behavior can be measured.
3. **Expectations tolerate drift.** Advisory databases, TLS behavior and line numbers change. The key anchors on file and text (not line numbers) and marks time- or environment-dependent items accordingly.
4. **Multiple repo states.** Tagged states (flawed, partially fixed, hardened) let the tool's baseline diffing and trend reporting be tested against known deltas.
5. **Safe by construction.** It is a public repo of deliberately vulnerable code. Fake credentials only, localhost only, nothing ever deployed, no working exploit payloads (see section 2).
6. **Small and boring.** A basic site, not a showcase. Realistic enough to produce realistic findings; small enough for one agent run per stage.

---

## 2. Safety Rules (public repo, intentionally vulnerable)

- README opens with a prominent warning: intentionally vulnerable, for scanner testing only, **never deploy**, no real data.
- All credentials, keys and tokens are **fake and non-functional**. Never use a real key, even a revoked one, and never a real customer, employer or internal name.
- Apps bind to `localhost`/`127.0.0.1` only. No public hosting, no tunnels, no cloud deployment, no DNS names that resolve. Outbound "external service" URLs use the reserved `.invalid` TLD or `localhost`.
- IaC, Dockerfile and Kubernetes fixtures are **never applied or run**. No provider credentials are configured anywhere.
- GitHub Actions workflows in the repo are harmless (echo-only "deploy" steps, no real secrets, no third-party actions beyond what the owner approves).
- The flaws are *patterns a scanner detects* (e.g., string-concatenated SQL), not step-by-step exploits. No exploit scripts, payload collections or weaponized examples.
- The canary project (section 6, Stage 1) only writes a marker file inside the repo's own `artifacts/` directory. No network, no reading other files, no persistence.

---

## 3. Decisions and Defaults

**Already decided (carried over from the evaluator project):** Windows development environment; public repo under the owner's GitHub account; agent asks before installing any tool or package; stop and ask the owner at every decision; one stage per run with review; feature branch per stage, one commit per task, owner merges.

**Open decisions the agent must ask about (do not assume):**

| # | Decision | Options and notes |
|---|---|---|
| D1 | Repo name and description | Suggest `soc2-evaluator-testbed`; owner confirms |
| D2 | Secret-seeding strategy | (a) commit only generic-pattern fake secrets (connection-string passwords, generic API keys) and generate provider-pattern fakes (AWS/GitHub/Slack-style) at test time via a gitignored script, (b) commit everything and use GitHub's push-protection bypass, (c) generic only. Provider-shaped fakes may be blocked by GitHub push protection even when fake. Recommendation: (a). |
| D3 | Legacy .NET Framework build tooling | Needs VS Build Tools/MSBuild plus the .NET Framework 4.8 targeting pack, and IIS Express to run. Options: install (with approval), or create the legacy project unbuilt and mark runtime checks as not verified. Recommendation: install, because Spike A needs a loadable legacy solution. |
| D4 | CICD-002 "secret scanning not enabled" | GitHub secret scanning is always on for public repos, so the "disabled" state cannot be reproduced here. Options: also create a small **private** repo with scanning off, or rely on recorded API-response fixtures, or accept the gap. Recommendation: recorded fixtures plus a documented gap. |
| D5 | Non-.NET languages | Node service is required; Python manifests optional; Java excluded unless the owner wants it |
| D6 | Cloud/IdP fixtures (Stage 4) | Recorded JSON snapshots (recommended) vs. a real sandbox tenant (cost and risk). Shape depends on the evaluator's Phase 4 collector contract, so this stage is gated on that design |
| D7 | Merge strategy | Merge commits (not squash) so tagged commits stay reachable on `main` |

---

## 4. The Site: "Ledgerly"

A tiny customer-invoice portal: sign in, list and search invoices, download an invoice file, admin page, a call to a payment gateway. Chosen because those features naturally attract the flaw types in the check catalog.

### Solutions and projects

| Project | Stack | Role |
|---|---|---|
| `src/LegacyPortal` | ASP.NET MVC 5, **.NET Framework 4.8**, old-style csproj, `packages.config`, `web.config` | Flawed legacy target. Spike A needs a real legacy solution. Also a deliberate edge case: `dotnet list package` does not read `packages.config`, so DEP-001 here is `best-effort` and depends on whether OSV-Scanner or another adapter handles it (verify during the build). |
| `src/ModernApi` | ASP.NET Core on current .NET LTS, PackageReference, `appsettings*.json` | Primary flawed target |
| `src/CleanApi` | ASP.NET Core, hardened | **Negative fixture.** Expected: zero or near-zero findings. Measures false positives. |
| `src/CanaryProject` | Small SDK-style project containing a benign repo-defined MSBuild target | Proves whether loading or restoring a scanned solution executes repo-defined code (Spike A and the threat model) |
| `services/node-service` | Node + Express, **with** `package-lock.json`, old pinned dependencies | `npm audit` and OSV targets (DEP-001, non-.NET) |
| `services/node-service-nolock` | Node, floating version ranges, **no** lockfile | DEP-002 (note: `npm audit` needs a lockfile, which is why this is a separate project) |
| `services/python-service` (optional, D5) | `requirements.txt` with old pins | Manifest-handling coverage |
| `infra/` | Terraform, Bicep, `Dockerfile`, `k8s/` manifests | IaC targets (IAC-001). Never applied. |
| `fixtures/` | Recorded cloud/IdP and GitHub API responses, evidence and org config samples | Phases 2, 4, 5 |
| `.github/workflows/`, `azure-pipelines.yml` | Pipeline definitions | CICD-001/002/003 |

### Repository layout

```
soc2-evaluator-testbed/
  README.md                         # safety warning first
  src/
    LegacyPortal/  ModernApi/  CleanApi/  CanaryProject/
    Testbed.sln                     # includes the SDK-style projects
    LegacyPortal.sln                # legacy solution kept separate for Spike A
  services/
    node-service/  node-service-nolock/  python-service/
  infra/
    terraform/  bicep/  docker/  k8s/
  fixtures/
    cloud/azure/  cloud/entra/  github-api/
    evidence/   org/   suppressions/
  scripts/
    run-modernapi.ps1  run-legacy.ps1  new-expiring-cert.ps1
    seed-secrets.ps1               # generates provider-pattern fakes (gitignored output)
    validate-oracle.ps1            # answer-key validator (section 8)
  oracle/
    expected-findings.yml          # answer key for this repo state
    secrets-registry.schema.md
  docs/
    seeded-issues.md               # human-readable inventory
    states.md                      # tags and variants
    limits.md                      # what this testbed cannot cover
  .github/workflows/  azure-pipelines.yml
  .gitignore  .gitattributes
```

---

## 5. Traceability: Evaluator Requirement to Testbed Artifact

| Evaluator plan item | What the testbed provides | Stage |
|---|---|---|
| Phase 0 Spike A: load legacy .NET Framework + .NET Core solutions with `MSBuildWorkspace`, measure success, cross-platform behavior, code executed on load | `LegacyPortal.sln`, `Testbed.sln`, `CanaryProject` (benign marker proves repo code runs on load/restore) | 1 |
| Phase 0 Spike B: wrap one scanner end to end | Seeded secrets and dependency flaws with known expected results | 1 |
| SEC-001 secrets; redaction test (seeded secrets never in output) | Committed generic fakes, generated provider-pattern fakes, `secrets-registry.json` of every seeded value | 1 |
| DEP-001 vulnerable packages (direct + transitive) | Pinned old NuGet packages (one with a vulnerable transitive dependency), npm lock with old pins, `packages.config` edge case, hardened versions in `CleanApi` | 1, 3 |
| CFG-002 verbose errors / debug in production | `web.config` debug/customErrors/trace, `UseDeveloperExceptionPage()` unconditional, production appsettings with debug logging | 1 |
| `--baseline` diffing | `stage1-remediated` variant with known fixes plus one introduced regression | 1 |
| False-positive measurement; positive and negative fixtures | `CleanApi`, traps list (section 7) | 1 to 3 |
| SEC-002 weak crypto | MD5 password hashing, SHA1 checksum, AES-ECB, hardcoded IV | 2 |
| SEC-003 missing `[Authorize]` / `AllowAnonymous` | Unprotected admin and export endpoints (Core and MVC 5); legitimate anonymous endpoints as negatives | 2 |
| SEC-004 TLS validation disabled | Always-true callbacks (HttpClient handler in Core, `ServicePointManager` in legacy) | 2 |
| SEC-005 SQL concatenation | Concatenated search query; parameterized equivalent in `CleanApi` | 2 |
| CFG-004 audit logging absence | No auth-event logging in `ModernApi`; present in `CleanApi` | 2 |
| CFG-005 permissive CORS | Any-origin CORS with credentials; explicit allow-list in `CleanApi` | 2 |
| DEP-002 no lockfile / unpinned | Floating NuGet versions with no lock file; `node-service-nolock` | 2, 3 |
| CICD-001/002/003 | Workflows and `azure-pipelines.yml` flaws; unprotected `main`; `production` environment with no required reviewers; recorded GitHub API fixtures | 2 |
| Suppression lifecycle | `fixtures/suppressions/` valid, expired, missing-approver, missing-ticket | 2 |
| CFG-001/CFG-003 + exposed paths (probe) | Runnable local sites with no HSTS, no redirect, no security headers, weak cookies, server disclosure, fake exposed paths, expiring self-signed cert | 3 |
| IAC-001 | Terraform, Bicep, Dockerfile, k8s misconfigurations | 3 |
| Non-.NET results; `npm audit`; OSV manifests | Node (and optional Python) services | 3 |
| `--fail-on`, SARIF, GitHub annotations | Known severities in the key; a workflow stub that can invoke the evaluator once it exists | 3 |
| CLD-001/CLD-002 | Recorded Entra/Azure snapshots: no admin MFA, legacy auth allowed, deployed state drifting from IaC; a clean snapshot | 4 (gated, D6) |
| PRC-001 evidence staleness | `evidence.complete/stale/partial.yml` | 5 |
| Per-org control mapping | `fixtures/org/acme-org.yml` with overrides | 5 |
| Trend report | Ordered tagged states `v1-flawed` to `v4-hardened` | 5 |

---

## 6. Seeded Issue Inventory

Values and package versions below are **candidates**. The agent must verify every claim against live tooling at build time and record the verified detail (advisory IDs, versions, date verified) in the answer key. Do not trust this table's package/advisory assumptions.

### Stage 1: foundations for tool Phases 0 and 1

| Check | Seed | Notes |
|---|---|---|
| SEC-001 | Connection-string password in `ModernApi/appsettings.json` and `LegacyPortal/web.config`; hardcoded generic API key constant; short literal JWT signing key | Generic fakes, committed. Provider-pattern fakes generated by `seed-secrets.ps1` (D2) |
| SEC-001 redaction | `secrets-registry.json` listing every seeded value (committed generics plus generated ones) | The evaluator's redaction test greps all outputs for these |
| DEP-001 | `ModernApi`: Newtonsoft.Json 12.0.3 (candidate, verify advisory) plus a direct package that pulls a vulnerable transitive dependency (agent finds and verifies); `LegacyPortal`: old packages in `packages.config`; `CleanApi`: current, no advisories | Record advisory IDs. Expectation is "at least one High or above", not exact counts |
| CFG-002 | `<compilation debug="true">`, `<customErrors mode="Off">`, `<trace enabled="true" localOnly="false">`; `UseDeveloperExceptionPage()` with no environment check; `appsettings.Production.json` with `Debug` logging and `DetailedErrors` | `CleanApi` gets this right |
| Canary | `CanaryProject` with a benign MSBuild target writing `artifacts/canary/executed.txt` (timestamp only) during evaluation/restore/build | Recorded in the key's `canaries` section, not as a finding |

### Stage 2: for tool Phase 2

| Check | Seed |
|---|---|
| SEC-002 | MD5 password hashing; SHA1 file checksum used as integrity control; AES with `CipherMode.ECB`; hardcoded IV |
| SEC-003 | Admin and export endpoints without `[Authorize]`; `[AllowAnonymous]` on a sensitive action; MVC 5 controller without `[Authorize]` |
| SEC-004 | Always-true `ServerCertificateCustomValidationCallback`; legacy `ServicePointManager.ServerCertificateValidationCallback` returning true |
| SEC-005 | String-concatenated SQL in invoice search (Core and legacy `SqlCommand`) |
| CFG-004 | `ModernApi` logs no login success/failure events (heuristic, low confidence) |
| CFG-005 | `AllowAnyOrigin()` with credentials; legacy `Access-Control-Allow-Origin: *` |
| DEP-002 | `ModernApi` uses floating versions and has no lock file or central pinning |
| CICD-001 | `main` has no branch protection or required reviews; no `CODEOWNERS` (default state of a new repo) |
| CICD-002 | Workflow with a fake token hardcoded in an `env:` block and echoed; `azure-pipelines.yml` with a plaintext password variable |
| CICD-003 | `deploy.yml` deploying (echo-only) to `environment: production` on push to `main` with no required reviewers; `azure-pipelines.yml` deploy stage with no approval or environment checks. Recorded GitHub API response fixtures for API-based collectors |
| Suppressions | Four sample `.soc2ignore.yml` files: valid, expired, missing approver, missing ticket |

### Stage 3: for tool Phase 3 (runtime and non-.NET)

| Check | Seed |
|---|---|
| CFG-001 | HTTP and HTTPS both served; no HTTP-to-HTTPS redirect; no HSTS; Kestrel configured to allow legacy TLS protocols (**environment dependent**: Windows may still refuse them); self-signed certificate generated by `new-expiring-cert.ps1` with a short validity so expiry findings reproduce on demand |
| CFG-003 | No security headers; cookies without Secure/HttpOnly/SameSite; `Server`, `X-Powered-By`, `X-AspNet-Version` disclosure |
| Exposed paths | `/.git/HEAD` served with fake content from a fixtures folder (not a real `.git` directory), stub `/elmah.axd`, `/trace.axd` via legacy trace config, `/swagger` enabled outside Development, a verbose-error endpoint |
| IAC-001 | Terraform and Bicep: public blob access, HTTPS-only off, minimum TLS 1.0, NSG open to the world on 22/3389, unencrypted disk, Key Vault without purge protection. Dockerfile: root user, `latest` tag, secrets in `ENV`. k8s: privileged, no resource limits, `hostNetwork` |
| DEP-001 (non-.NET) | `node-service` old pins with lockfile (candidate: lodash 4.17.15, verify); optional Python pins |
| DEP-002 (non-.NET) | `node-service-nolock` floating ranges, no lockfile |

### Stage 4: for tool Phase 4 (gated)

Recorded snapshots shaped to the evaluator's Phase 4 collector contract. CLD-001: Entra conditional-access JSON with no MFA requirement for admin roles and legacy authentication allowed. CLD-002: a deployed-state snapshot with public blob access, no backups, no diagnostic settings, while the IaC in `infra/` declares the opposite (drift). Plus a clean snapshot as a negative.

### Stage 5: for tool Phase 5

PRC-001: `evidence.complete.yml`, `evidence.stale.yml` (items older than the staleness threshold), `evidence.partial.yml` (unanswered controls). Org mapping: `acme-org.yml` overriding IDs and severities, with one rule disabled with justification. Ordered state tags for trends. Optional Availability/Confidentiality seeds once the evaluator plan defines those checks.

---

## 7. Negatives and False-Positive Traps

These must be in the key with `detection: negative` or `trap` so false positives are measurable.

| Item | Expectation |
|---|---|
| `[AllowAnonymous]` on `/login` and `/health` | Must not be flagged as SEC-003 |
| Placeholder values (`YOUR_API_KEY_HERE`, `changeme` in docs and `.env.example`) | Must not be flagged as secrets |
| Fake test-only key under `tests/` with an inline suppression note | Acceptable as suppressed; flagged-then-suppressed path is tested |
| MD5 used for a non-security cache key, with an explanatory comment | `trap`: low confidence or finding both acceptable, recorded either way |
| High-entropy non-secrets (GUIDs, commit SHAs, a small base64 image) | Must not be flagged by entropy rules |
| Debug settings only in `appsettings.Development.json` | Must not be flagged as CFG-002 |
| Parameterized SQL, explicit CORS allow-list, redirect plus HSTS, auth-event logging in `CleanApi` | Must not be flagged |

`CleanApi` as a whole is the headline negative. Note that three synthetic projects do **not** replace the evaluator plan's "false-positive review on 3+ real projects"; the testbed supplements it (see section 11).

---

## 8. The Answer Key and Validator

### `oracle/expected-findings.yml` (schema v1)

```yaml
schemaVersion: 1
repoState: stage1-flawed
generated: 2026-11-10
issues:
  - id: TB-001
    checkId: SEC-001
    title: Connection string password in appsettings
    category: Configuration        # Code | Configuration | Process
    expectedSeverity: high
    file: src/ModernApi/appsettings.json
    anchor: "Password="            # text anchor, never a line number
    defaultTsc: [CC6.1]
    detection: required            # required | best-effort | environment-dependent
    expectedSources: [gitleaks]
    remediation: Move to a secret store / environment variable
    verified: {tool: "gitleaks", version: "...", date: "..."}
negatives:
  - id: TB-N-001
    file: src/ModernApi/Controllers/HealthController.cs
    anchor: "[AllowAnonymous]"
    mustNotFlag: [SEC-003]
    why: Legitimate anonymous health endpoint
canaries:
  - id: TB-C-001
    project: src/CanaryProject
    marker: artifacts/canary/executed.txt
    meaning: Present after load/restore/build if repo-defined code executed
secrets:
  registry: oracle/secrets-registry.json   # values generated or committed; gitignored when generated
```

Time-varying items (advisories, TLS negotiation) use `detection: best-effort` or `environment-dependent`, with the verification date and tool version recorded.

### `scripts/validate-oracle.ps1` (required)

Checks that: every `file` exists and every `anchor` text occurs in it; every committed seeded secret appears in the registry; no committed file contains a value that looks like a real credential beyond the registry (a guard against accidental real secrets); every negative's anchor exists; every issue has a unique ID; schema fields are present. It runs in CI on the testbed repo.

---

## 9. Repo States and Variants

| Tag / branch | Contents | Used for |
|---|---|---|
| `testbed-stageN-flawed` | Full flawed state at the end of each stage | Per-phase tool testing |
| `variant/stage1-remediated` (branch, not merged) | Stage 1 with roughly half the issues fixed and **one new regression introduced**, with its own `expected-findings.yml` | `--baseline` diffing: expects resolved, persisting and new findings |
| `testbed-v1-flawed` to `testbed-v4-hardened` (after Stage 5) | Progressive remediation series | Trend report, mean time to remediate |

`docs/states.md` documents what changed between states. Per D7, merge commits preserve tagged commits on `main`.

---

## 10. Stages

Each stage is one agent run ending in review. Dependencies on the evaluator: **Stage 0 and 1 must exist before the evaluator's Phase 0 spikes**, so build them first.

### Stage 0: Bootstrap and conventions
- Resolve D1 to D7 with the owner. Create the repo, `main` with README (safety warning), `.gitignore`, license only if the owner names one, a copy of this plan, and the oracle schema document
- Feature branch for the stage; tasks as one commit each
- Write `validate-oracle.ps1` and a CI workflow that runs it
- **Exit:** validator runs green on an empty key; README safety text reviewed

### Stage 1: Legacy + Core solutions, secrets, dependencies, debug config, canary
- Build `LegacyPortal`, `ModernApi`, `CleanApi`, `CanaryProject` with only enough Ledgerly functionality (login, invoice list) to be realistic
- Seed SEC-001, DEP-001, CFG-002; add the secrets registry and `seed-secrets.ps1`
- Create the key; create `variant/stage1-remediated` with its own key; tag `testbed-stage1-flawed`
- **Exit:** both solutions load (or the legacy limits are recorded per D3); `dotnet list package --vulnerable` confirms the DEP-001 seeds and `CleanApi` shows none; the canary marker appears on a load/restore/build; validator green; every seeded item verified independently where tooling is approved

### Stage 2: Code flaws, pipelines, suppressions
- Seed SEC-002 to SEC-005, CFG-004, CFG-005, DEP-002, negatives and traps
- Workflows, `azure-pipelines.yml`, GitHub API response fixtures, suppression samples
- Configure the GitHub repo state needed for CICD-001/003 (leave `main` unprotected; create a `production` environment without reviewers) **only after the owner approves each setting change**
- **Exit:** key complete for Stage 2; negatives verified not to trip an independent search for the flaw patterns; workflows run harmlessly

### Stage 3: Runtime behavior, IaC, non-.NET
- Make both web apps runnable locally on localhost with the seeded runtime behavior; `run-*.ps1` scripts; `new-expiring-cert.ps1`
- IaC and Dockerfile/k8s fixtures; Node (and optional Python) services
- **Exit:** every runtime behavior verified with a recorded request/response transcript (headers, cookies, redirects, exposed paths); `npm audit` confirms the Node seeds; IaC files parse (without applying); environment-dependent items marked

### Stage 4: Cloud and identity snapshots (gated on evaluator Phase 4 design)
- Stop and ask the owner for the evaluator's collector contract and decide D6; then build snapshots and the matching drift pair
- **Exit:** snapshots validate against the contract; clean snapshot included

### Stage 5: Process evidence, org config, history series
- Evidence samples, org mapping, suppression variants finalized
- Produce the ordered state series `v1` to `v4` with keys and `docs/states.md`
- **Exit:** series diffs match the keys; validator green on every tagged state

---

## 11. Known Limits (write these into `docs/limits.md`)

- **Synthetic projects cannot replace real-project false-positive review.** The evaluator plan still needs 3+ real projects.
- **Secret scanning cannot be shown "off" on a public repo** (D4).
- **Real cloud/IdP posture is not exercised**; Stage 4 uses recorded snapshots, so collector authentication and API behavior are untested.
- **Azure DevOps API behavior** is untested without an ADO organization; only pipeline files and recorded responses are covered.
- **TLS protocol-version weaknesses** depend on the host OS and may not be reproducible on localhost.
- **Advisory databases change.** DEP findings drift over time; the key records verification dates and uses loose expectations.
- **Windows-only legacy app.** The .NET Framework project cannot be run on Linux or macOS, so cross-platform behavior of the evaluator is not tested for it.

---

## 12. Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Accidental real secret committed | Fake-only rule, validator guard, pre-commit review of every secret value, owner approval for D2 |
| Push protection blocks fixtures | D2 strategy; generate provider-pattern fakes at test time |
| Testbed code mistaken for a reference implementation | README warning, `docs/limits.md`, clean reference clearly labeled |
| Key rot as tools and advisories change | Anchors not line numbers, verification dates, loose expectations, validator in CI |
| Scope creep into a real application | Strict "Ledgerly" feature list: login, invoice list/search/download, admin page, gateway call |
| Public repo attracting misuse | No exploit content; flaws are scanner-detectable patterns only |
| Legacy build tooling unavailable | D3; record the limitation instead of faking results |

---

## 13. Immediate Next Steps

1. Review and approve this plan (and answer D1 to D7 when the agent asks)
2. Run Stage 0, then Stage 1, before starting the evaluator's Phase 0 spikes
3. Point the evaluator agent's "real sample project" at this repo's tagged states
4. After the evaluator's Phase 4 design exists, run Stage 4 with the real collector contract
