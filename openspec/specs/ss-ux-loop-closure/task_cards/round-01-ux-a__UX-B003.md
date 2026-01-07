# [ROUND-01-UX-A] UX-B003: Worker 执行闭环（DoFileGenerator + 可配置 StataRunner + 可用产物）

## Metadata

- Priority: P0 (Blocker)
- Issue: #128 https://github.com/Leeky1017/SS/issues/128
- Audit: #124 https://github.com/Leeky1017/SS/issues/124
- Spec: `openspec/specs/ss-ux-loop-closure/spec.md`
- Related specs:
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-llm-brain/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-state-machine/spec.md`

## Problem (from audit)

Even after enqueueing, the default worker configuration cannot produce “user-meaningful results”:
- Worker depends on `job.llm_plan`; without UX-B002 it fails with `PLAN_MISSING`
- Worker plan execution does not use `DoFileGenerator` (it generates a stub do-file)
- Worker uses `FakeStataRunner` unconditionally, so it never calls real Stata and cannot produce real exported outputs

Evidence: `Audit/04_Production_Readiness_UX_Audit.md`

## Goal

Make the worker execution path runnable and auditable so a user can:
- confirm → enqueue → worker executes
- obtain at least one downloadable “result” artifact plus logs

## Scope (v1)

### Execution wiring (normative)

Worker MUST execute a queued job by:
1) Loading job and asserting `llm_plan` exists
2) Loading inputs manifest (from `job.inputs.manifest_rel_path`)
3) Generating do-file using `DoFileGenerator(plan=job.llm_plan, inputs_manifest=...)`
4) Executing via a configurable `StataRunner`
5) Persisting run evidence artifacts and updating job status

### Runner selection (configurable)

Runner MUST be selected from config:
- If `SS_STATA_CMD` is configured (non-empty), prefer `LocalStataRunner`
- Otherwise, allow `FakeStataRunner` for dev/test

### Minimal success artifacts

On success, the artifacts index MUST include at least:
- `stata.do` (kind: `stata.do`)
- `stata.log` (kind: `stata.log`)
- `run.meta.json` (kind: `run.meta.json`)
- an exported table file (kind: `stata.export.table`)

Note: current `DoFileGenerator` baseline template exports `ss_summary_table.csv`.

### Failure artifacts (structured + downloadable)

On failure, the artifacts index MUST include enough evidence to debug without reading server logs:
- `run.stdout`, `run.stderr`, `stata.log`, `run.meta.json`
- `run.error.json` (kind: `run.error.json`) with stable `error_code` + `message`

Special case: failures before invoking the runner (e.g. `PLAN_MISSING`, manifest missing/invalid)
- MUST still produce `run.meta.json` + `run.error.json` under the run attempt directory
- MUST still transition job to `failed` via the state machine

### Safety constraints

- Execution MUST be isolated to the run attempt directory (`runs/<run_id>/work`)
- Inputs used by Stata MUST be copied into the run workspace (no reading outside job workspace)
- Do-file safety rules MUST be enforced (no traversal/unsafe writes)

## Testing requirements

Minimum tests (suggested):
- End-to-end (journey A): create job → upload dataset → draft preview → plan freeze → confirm → worker executes → artifacts include export table + logs → download works
- Failure path: force runner failure and assert `run.error.json` exists and job becomes `failed`
- Pre-run failure path: missing plan or missing manifest produces evidence artifacts (meta + error)

## Acceptance checklist

- [ ] Worker uses `DoFileGenerator` for `GENERATE_STATA_DO` step (no stub do-file)
- [ ] Worker runner is configurable (Local vs Fake)
- [ ] Success produces at least one export-table artifact plus logs/meta/do-file
- [ ] Failure produces structured `run.error.json` and downloadable evidence artifacts
- [ ] User journey tests cover the HTTP path + worker execution to downloadable artifacts

