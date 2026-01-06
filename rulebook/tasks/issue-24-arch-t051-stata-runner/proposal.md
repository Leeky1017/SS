# Proposal: issue-24-arch-t051-stata-runner

## Summary

- Introduce a single domain port (`StataRunner`) for all Stata execution.
- Add an infra implementation (`LocalStataRunner`) that runs Stata via subprocess inside the run attempt workspace and captures artifacts.
- Provide structured errors for timeout and non-zero exit code paths, with evidence files for audit/debugging.

## Changes

### ADDED

- `src/domain/stata_runner.py`: runner port + `RunResult`/error models.
- `src/infra/local_stata_runner.py`: subprocess-based runner enforcing workspace boundaries.

### MODIFIED

- Tests to cover success/timeout/non-zero exit, without requiring real Stata.

## Impact

- Affected specs: `openspec/specs/ss-stata-runner/spec.md`, `openspec/specs/ss-job-contract/spec.md`
- Affected code: `src/domain/`, `src/infra/`, `tests/`
- Breaking change: NO
- User benefit: Safe, auditable, single-boundary Stata execution with reproducible artifacts.
