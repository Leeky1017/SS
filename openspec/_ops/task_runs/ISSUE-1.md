# ISSUE-1

- Issue: #1
- Branch: task/1-ss-infra-bootstrap
- PR: https://github.com/Leeky1017/SS/pull/2

## Plan
- Add OpenSpec/Rulebook skeleton + docs
- Add GitHub checks (ci/openspec-log-guard/merge-serial)
- Verify ruff/pytest green

## Runs
### 2026-01-06 bootstrap
- Command:
  - `ruff check .`
  - `pytest -q`
- Key output:
  - `All checks passed!`
  - `3 passed in 0.01s`
