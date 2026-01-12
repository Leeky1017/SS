# Proposal: issue-424-stata-infra-coverage

## Why
Overall test coverage is currently ~79%, which is below the intended 80% CI coverage gate. The Stata integration boundary has low coverage, making regressions around dependency preflight and command resolution harder to catch.

## What Changes
- Add deterministic unit tests for `LocalStataDependencyChecker` helper functions and `check()` behavior.
- Add deterministic unit tests for `resolve_stata_cmd`, `build_stata_batch_cmd`, and WSL Windows interop validation behavior.

## Impact
- Affected specs: `rulebook/tasks/issue-424-stata-infra-coverage/specs/ss-stata-infra-coverage/spec.md`
- Affected code:
  - `src/infra/local_stata_dependency_checker.py`
  - `src/infra/stata_cmd.py`
  - New tests under `tests/`
- Breaking change: NO
- User benefit: Safer, explicitly tested Stata preflight/error handling and command resolution behavior.
