# [ROUND-01-UX-A] UX-B002: 确认前冻结 Plan + 对外可预览

## Metadata

- Priority: P0 (Blocker)
- Issue: #127 https://github.com/Leeky1017/SS/issues/127
- Audit: #124 https://github.com/Leeky1017/SS/issues/124
- Spec: `openspec/specs/ss-ux-loop-closure/spec.md`
- Related specs:
  - `openspec/specs/ss-llm-brain/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-state-machine/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`

## Problem (from audit)

Worker execution depends on `job.llm_plan`, but the current public HTTP UX path never freezes a plan:
- `PlanService.freeze_plan()` exists (deterministic stub), but it is not reachable via HTTP
- `POST /v1/jobs/{job_id}/confirm` can enqueue jobs without ensuring `llm_plan` exists
- Result: worker sees `PLAN_MISSING` and the loop cannot complete

Evidence: `Audit/04_Production_Readiness_UX_Audit.md`

## Goal

Make plan freeze a **first-class, user-path** step so:
- a job cannot enter `queued` without a frozen plan
- users can preview the plan they are about to run
- plan persistence is fully auditable (job.json + plan artifact)

## Scope (v1)

### Plan freeze integration

SS MUST ensure one of the following is true (pick one design; both are acceptable):

Option A (preferred UX): confirm auto-freezes
- `POST /v1/jobs/{job_id}/confirm` freezes the plan (if missing) before enqueueing

Option B (explicit step): separate freeze endpoint + confirm guard
- `POST /v1/jobs/{job_id}/plan/freeze` freezes the plan
- `POST /v1/jobs/{job_id}/confirm` rejects with a structured error if plan is missing

### Plan preview

Users MUST be able to preview the frozen plan before execution.

Acceptable surfaces:
- `GET /v1/jobs/{job_id}/plan` (direct)
  - or
- plan is downloadable via artifacts:
  - the plan artifact is always indexed as `kind=plan.json` at `artifacts/plan.json`
  - users use `GET /v1/jobs/{job_id}/artifacts/...` to download it

### Confirmation payload

`PlanService.freeze_plan()` takes a `JobConfirmation` payload. v1 MUST define how the API supplies it.

Recommended (minimal v1):
- If the request provides no confirmation payload, SS uses:
  - `JobConfirmation(requirement=job.requirement)`
- Optionally allow client-provided notes:
  - `JobConfirmation(notes=...)`

### Idempotency and conflicts

- Calling plan-freeze repeatedly with the same logical inputs MUST be idempotent.
- If a plan is already frozen but the requested confirmation differs, SS MUST fail with a structured error (no silent overwrite).

Recommended `error_code` set (v1):
- `PLAN_FREEZE_NOT_ALLOWED` (status not draft_ready/confirmed)
- `PLAN_ALREADY_FROZEN_CONFLICT`

### Persistence requirements (normative)

Freezing a plan MUST:
- write `job.llm_plan` in `job.json`
- write `artifacts/plan.json` (job-relative)
- index `artifacts/plan.json` in `job.artifacts_index` as kind `plan.json`

## Testing requirements

User-journey tests MUST not call `PlanService.freeze_plan()` directly. They MUST exercise the HTTP path.

Minimum tests (suggested):
- Draft preview → plan freeze/preview → confirm queues without `PLAN_MISSING`
- Repeated confirm is idempotent (does not duplicate plan artifacts)
- Plan conflict returns structured error

## Acceptance checklist

- [ ] The user path guarantees plan exists before `queued`
- [ ] Plan is previewable via API or artifacts download
- [ ] Plan persistence matches `ss-llm-brain` contract (job.json + artifacts + index)
- [ ] Idempotency + conflict behaviors are covered by tests
- [ ] User journey tests no longer call `PlanService.freeze_plan()` directly

