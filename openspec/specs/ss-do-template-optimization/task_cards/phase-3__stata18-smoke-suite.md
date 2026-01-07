# Phase 3: Stata 18 Smoke Suite + Evidence Harness

## Metadata

- Issue: #158
- Parent: #125
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-do-template-optimization/spec.md`

## Goal

Provide reproducible evidence that templates run on real Stata 18 (where licensing permits), and prevent regressions via strong static gates when Stata is unavailable in CI.

## In scope

- Define a smoke-suite manifest:
  - template_id → fixture dataset(s) + minimal params
  - dependency notes (built-in vs SSC)
- Add a runnable local command to execute the smoke suite and write a structured report.
- Ensure static gates remain strong in CI even if Stata cannot be executed there.

## Out of scope

- Running Stata inside CI if license/environment cannot support it.
- Full correctness proofs for all statistical outputs (smoke only).

## Acceptance checklist

- [ ] Smoke-suite manifest exists and covers the “core” template subset
- [ ] Local execution writes a structured report (pass/fail + missing deps + outputs)
- [ ] Evidence is captured in `openspec/_ops/task_runs/ISSUE-<N>.md` for the implementation issue
