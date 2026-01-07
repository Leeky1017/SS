# Phase 2: API versioning + deprecation policy

## Metadata

- Issue: #83 https://github.com/Leeky1017/SS/issues/83
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`

## Background

The audit found that routes are not versioned and there is no deprecation policy, making it hard to introduce breaking changes safely while supporting existing clients.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “缺乏 API 版本管理与弃用政策”
- `Audit/03_Integrated_Action_Plan.md` → “任务 2.2：API 版本管理”

## Goal

Introduce explicit API versioning (at least `/v1`) and define a deprecation mechanism (headers + schedule) so new versions can coexist without silent client breakage.

## Deprecation schedule

- Legacy unversioned routes (`/jobs/*`) are deprecated once `/v1` is available.
- Sunset date (planned removal): `2026-06-01` (emitted via the `Sunset` response header).

## Dependencies & parallelism

- Hard dependencies: none
- Parallelizable with: LLM timeout/retry, distributed storage evaluation

## Acceptance checklist

- [ ] API routes are served under an explicit version prefix (at least `/v1`)
- [ ] A deprecation mechanism is defined (e.g., `Deprecation` and `Sunset` headers) and documented
- [ ] Version introduction strategy is documented (when to create `/v2`, how long `/v1` stays supported)
- [ ] Tests cover that both versions can coexist during the deprecation window (where applicable)
- [ ] Implementation run log records `ruff check .`, `pytest -q`, and `openspec validate --specs --strict --no-interactive`

## Estimate

- 3-5h
