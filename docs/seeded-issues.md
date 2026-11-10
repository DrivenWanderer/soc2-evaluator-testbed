# Seeded Issues Inventory (Ground Truth)

This document tracks all intentionally seeded flaws, negative control fixtures, and canaries present in `soc2-evaluator-testbed`.

---

## Stage 1: Foundations (Phases 0 and 1)

### Positive Findings (`issues`)

| ID | Check ID | Category | Severity | Location | Text Anchor | Detection | Verification |
|---|---|---|---|---|---|---|---|
| **TB-001** | SEC-001 | Configuration | High | `src/ModernApi/appsettings.json` | `Password=` | Required | `validate-oracle.ps1` (text anchor verified) |
| **TB-002** | DEP-001 | Configuration | High | `src/ModernApi/ModernApi.csproj` | `Newtonsoft.Json` | Required | `dotnet list package --vulnerable` (GHSA-5crp-9r3c-p9vr) |
| **TB-003** | CFG-002 | Configuration | Medium | `src/ModernApi/Program.cs` | `app.UseDeveloperExceptionPage();` | Required | `validate-oracle.ps1` (text anchor verified) |
| **TB-004** | CFG-002 | Configuration | Medium | `src/ModernApi/appsettings.Production.json` | `DetailedErrors` | Required | `validate-oracle.ps1` (text anchor verified) |
| **TB-005** | SEC-001 | Code | High | `src/ModernApi/Services/PaymentGatewayService.cs` | `ledgerly_fake_api_key_99887766554433221100` | Required | `validate-oracle.ps1` (text anchor verified) |
| **TB-006** | SEC-001 | Code | High | `src/ModernApi/Program.cs` | `SyntheticShortSecretKey123!` | Required | `validate-oracle.ps1` (text anchor verified) |
| **TB-007** | DEP-001 | Configuration | High | `src/LegacyPortal/packages.config` | `Newtonsoft.Json` | Best-effort | `validate-oracle.ps1` (packages.config anchor verified) |
| **TB-008** | SEC-001 | Configuration | High | `src/LegacyPortal/web.config` | `Password=LegacyPortalFakeSqlPassword2026#` | Required | `validate-oracle.ps1` (text anchor verified) |
| **TB-009** | CFG-002 | Configuration | Medium | `src/LegacyPortal/web.config` | `<compilation debug="true"` | Required | `validate-oracle.ps1` (text anchor verified) |
| **TB-010** | CFG-002 | Configuration | Medium | `src/LegacyPortal/web.config` | `<customErrors mode="Off"` | Required | `validate-oracle.ps1` (text anchor verified) |
| **TB-011** | CFG-002 | Configuration | Low | `src/LegacyPortal/web.config` | `<trace enabled="true"` | Required | `validate-oracle.ps1` (text anchor verified) |

### Negative Control Fixtures (`negatives`)

| ID | File | Anchor | Must Not Flag | Purpose / Explanation |
|---|---|---|---|---|
| **TB-N-001** | `src/CleanApi/Controllers/HealthController.cs` | `[AllowAnonymous]` | `[SEC-003]` | Legitimate anonymous health probe endpoint; must not trigger missing authorization finding. |

### Canaries (`canaries`)

| ID | Project | Marker File | Purpose / Explanation |
|---|---|---|---|
| **TB-C-001** | `src/CanaryProject` | `artifacts/canary/executed.txt` | Benign MSBuild target executing on load/restore/build to test execution isolation in scanner host. |

---

## Variant Branch Seeds (`variant/stage1-remediated`)

- **Resolved Issues (6):** `TB-001`, `TB-002`, `TB-003`, `TB-004`, `TB-009`, `TB-010`.
- **Persisting Issues (5):** `TB-005`, `TB-006`, `TB-007`, `TB-008`, `TB-011`.
- **New Regression (1):**
  - **TB-012** (SEC-001, Code, High): Hardcoded internal service secret token in `src/ModernApi/Services/InternalSyncService.cs` (`SyntheticRegressionSecretToken456!`).
