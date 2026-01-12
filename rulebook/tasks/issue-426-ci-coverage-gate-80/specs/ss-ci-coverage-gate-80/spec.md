# Spec: ss-ci-coverage-gate-80 (issue-426)

## Purpose

Raise the CI coverage baseline gate to 80% now that overall coverage exceeds that threshold.

## Requirements

### Requirement: Required CI workflows enforce 80% coverage

SS MUST update required GitHub Actions workflows (`ci` and `merge-serial`) to run:

- `pytest -q --cov=src --cov-report=term-missing --cov-fail-under=80`

### Requirement: OpenSpec testing strategy reflects the new baseline

SS MUST update `openspec/specs/ss-testing-strategy/` to state that the CI baseline coverage gate is 80%.

