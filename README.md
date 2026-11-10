# SOC 2 Evaluator Testbed

> [!CAUTION]
> **WARNING: INTENTIONALLY VULNERABLE TEST REPOSITORY — DO NOT DEPLOY**
>
> This repository contains deliberately flawed code, vulnerable dependencies, insecure configurations, and synthetic secrets designed solely as test fixtures and ground-truth benchmarks for the [SOC 2 Evaluator](https://github.com/DrivenWanderer/soc2-evaluator) readiness tool.
>
> - **NEVER DEPLOY, HOST PUBLICLY, OR RUN IN PRODUCTION.**
> - **NO REAL CREDENTIALS:** All API keys, passwords, private keys, connection strings, and tokens in this repository are synthetic, non-functional fakes.
> - **LOCALHOST ONLY:** Any runnable application binds strictly to `localhost` / `127.0.0.1`. Outbound service mocks target `localhost` or the reserved `.invalid` top-level domain.
> - **NON-OPERATIONAL FIXTURES:** Infrastructure-as-Code (Terraform, Bicep), Dockerfiles, and Kubernetes manifests are static fixtures intended for scanner evaluation and must never be applied to real cloud or cluster environments.
> - **NO EXPLOIT PAYLOADS:** Seeded flaws are scanner-detectable code patterns and configurations only. No functional exploit code, weaponized scripts, or attack tooling are present.

---

## Overview

`soc2-evaluator-testbed` is the purpose-built test target for `soc2-evaluator`. It exercises the evaluator's check catalog (covering Trust Services Criteria across Security/Common Criteria CC6, CC7, and CC8) against a ground-truth answer key located at `oracle/expected-findings.yml`.

### Key Components

- **`src/LegacyPortal`**: ASP.NET MVC 5 on .NET Framework 4.8 (`packages.config`, `web.config`) for legacy solution testing.
- **`src/ModernApi`**: ASP.NET Core on current .NET LTS containing primary seeded flaws.
- **`src/CleanApi`**: Hardened ASP.NET Core application serving as the negative control fixture (measures false positives).
- **`src/CanaryProject`**: Benign SDK-style project with an MSBuild marker target to verify load/restore isolation.
- **`services/`**: Node.js services testing dependency auditing (`npm audit`) and unpinned/lockfile detection.
- **`infra/`**: Static IaC fixtures (Terraform, Bicep, Dockerfile, Kubernetes) exercising static configuration scanners.
- **`oracle/`**: Machine-readable answer key (`expected-findings.yml`) and schema definitions.
- **`scripts/`**: Operational scripts including `validate-oracle.ps1` for automated ground-truth validation.

## Documentation

- [Testbed Implementation Plan](docs/plan.md)
- [Evaluator Plan Reference](https://github.com/DrivenWanderer/soc2-evaluator/blob/main/docs/plan.md)
- [Decisions Log](docs/decisions.md)
- [Progress Log](docs/progress.md)

## License

This repository is licensed under the [MIT License](LICENSE).
