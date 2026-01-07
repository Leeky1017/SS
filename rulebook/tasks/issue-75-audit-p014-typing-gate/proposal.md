# Proposal: ISSUE-75 Type annotations + mypy gate

## Summary
- ADDED: mypy dev dependency + strict config (`pyproject.toml`)
- MODIFIED: missing/invalid return type annotations in `src/`
- MODIFIED: CI workflows to run type check (`.github/workflows/*.yml`)
- MODIFIED: developer workflow note for running the type check locally
- ADDED: `openspec/_ops/task_runs/ISSUE-75.md` (run log)

## Rationale
The audit identified incomplete type annotations, which weakens IDE support and allows type regressions to slip into PRs. Adding a CI-enforced static typing gate (mypy strict) and filling missing return annotations makes typing a maintained contract instead of a one-time cleanup.

## Impact
- Affected code: `src/`, CI workflows
- Breaking change: no (static typing only)
