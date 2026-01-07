# Phase 2: API versioning + deprecation policy

## Background

The audit found that routes are not versioned and there is no deprecation policy, making it hard to introduce breaking changes safely while supporting existing clients.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “缺乏 API 版本管理与弃用政策”
- `Audit/03_Integrated_Action_Plan.md` → “任务 2.2：API 版本管理”

## Goal

Introduce explicit API versioning (at least `/v1`) and define a deprecation mechanism (headers + schedule) so new versions can coexist without silent client breakage.

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

