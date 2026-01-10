# Proposal: issue-340-prod-e2e-r013

## Why
Production E2E audit requires removing the stub do-file generator and making template rendering +
evidence archiving deterministic and complete in the worker execution chain.

## What Changes
- Replace the `stub_descriptive_v1` generator path with do-template library rendering only.
- Fail fast with structured error when required template parameters are missing (no runner invocation).
- Persist full template/run evidence in run artifacts (template source/meta/params + do-template run meta).

## Impact
- Affected specs:
  - `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`
- Affected code:
  - `src/domain/do_file_generator.py`
  - `src/domain/worker_plan_executor.py`
  - `src/infra/stata_run_attempt.py`
- Breaking change: NO (worker chain remains functional; removes legacy stub-only path)
- User benefit: Deterministic do-file generation and audit-grade artifacts for debugging/retries
