# [OPS] PROD-AUDIT-02: Run production E2E journey (real Stata + real LLM)

## Metadata

- Priority: P0
- Issue: #274 https://github.com/Leeky1017/SS/issues/274
- Spec: `openspec/specs/ss-production-e2e-audit/spec.md`
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-worker-queue/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`

## Goal

Execute the `/v1` journey end-to-end against a production-like SS start (API + worker), using:
- real Stata runner (not fake)
- real (non-stub) LLM provider with `SS_LLM_MODEL=claude-opus-4-5-20251101`

Collect evidence sufficient for a go/no-go decision.

## In scope

- Start API + worker in separate processes.
- Perform the full journey:
  - redeem → upload CSV → inputs preview → draft preview → plan freeze → run → artifacts → restart → recover
- Download and validate at least:
  - `artifacts/plan.json` (or equivalent)
  - `stata.do` and `stata.log` (or equivalent runner outputs)
  - at least one data artifact (e.g., summary table CSV)
- Confirm that artifacts remain downloadable after restart.

## Out of scope

- Fixing any failures (audit-only).

## Acceptance checklist

- [ ] Run log includes exact process start commands (API/worker) and key logs showing runner type + executed Stata command.
- [ ] Run log includes HTTP requests, status codes, and key response fields for every step.
- [ ] Draft preview evidence includes variable extraction and clarification mechanism fields.
- [ ] Plan freeze evidence includes: template reference, param binding, dependencies, artifact contract/index.
- [ ] Artifacts are downloaded to a local path and validated against the declared contract.
- [ ] Evidence captured in `openspec/_ops/task_runs/ISSUE-274.md`.

