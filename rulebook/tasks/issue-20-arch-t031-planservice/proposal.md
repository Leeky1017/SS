# Proposal: issue-20-arch-t031-planservice

## Why
We need a schema-bound, deterministic plan (`LLMPlan`) that can be frozen into `job.json` and replayed from artifacts, so downstream worker/runner code can be audited and remain stable.

## What Changes
- Add `LLMPlan` step schema (type/params/depends_on/produces) in domain models.
- Add `PlanService` deterministic stub that freezes a plan into `job.json` and writes `artifacts/plan.json`.
- Add unit tests for plan generation, freezing, and idempotent re-freeze.

## Impact
- Affected specs:
  - `openspec/specs/ss-llm-brain/spec.md`
  - `openspec/specs/ss-job-contract/README.md`
- Affected code:
  - `src/domain/models.py`
  - `src/domain/plan_service.py` (new)
  - `src/infra/job_store.py` (plan artifact write helper)
  - `tests/test_plan_service.py` (new)
- Breaking change: YES (job.json `llm_plan` becomes structured)
- User benefit: Plan becomes auditable, replayable, and stable for the worker pipeline.
