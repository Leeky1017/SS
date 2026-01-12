# Proposal: issue-415-ci-coverage-gate

## Why
CI currently runs `pytest -q` without enforcing coverage, so coverage regressions can land unnoticed.
The repo baseline is ~79% overall coverage; adding a conservative `--cov-fail-under=75` gate prevents drift while keeping the bar realistic.

## What Changes
- Add `pytest-cov` to `.[dev]` (CI installs `pip install -e ".[dev]"`).
- Update GitHub Actions (`ci` + `merge-serial`) to run pytest with `--cov=src --cov-fail-under=75`.
- Update OpenSpec to record the coverage gate as a baseline quality constraint.

## Impact
- Affected specs: `openspec/specs/ss-testing-strategy/spec.md`
- Affected code: `.github/workflows/ci.yml`, `.github/workflows/merge-serial.yml`, `pyproject.toml`
- Breaking change: NO
- User benefit: Prevents test coverage regressions in mainline delivery.
