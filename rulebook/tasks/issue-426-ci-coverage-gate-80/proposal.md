# Proposal: issue-426-ci-coverage-gate-80

## Why
Overall coverage is now above 80%, so we can tighten the CI coverage gate to prevent regressions and enforce the new baseline.

## What Changes
- Raise CI coverage threshold from 75% to 80% in required workflows (`ci`, `merge-serial`).
- Update the authoritative testing strategy spec to reflect the new baseline.

## Impact
- Affected specs:
  - `openspec/specs/ss-testing-strategy/spec.md`
  - `openspec/specs/ss-testing-strategy/README.md`
- Affected code:
  - `.github/workflows/ci.yml`
  - `.github/workflows/merge-serial.yml`
- Breaking change: NO (but stricter CI checks)
- User benefit: Prevents silent coverage drift and keeps the quality bar consistent.
