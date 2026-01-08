# Tasks: issue-186-p53-data-prep-ta

## Spec-first

- [ ] Confirm Phase 4.3 completed for `TA01`–`TA14` baseline quality.
- [ ] Align with Phase 5.3 task card acceptance.

## Implementation

- [ ] Add best-practice review record to each `TA*` template.
- [ ] Add data-prep best practices: missingness checks, outlier diagnostics, type/unique checks, deterministic transformations.
- [ ] Strengthen error handling: explicit `SS_RC` warn/fail; avoid silent `capture` swallowing.
- [ ] Add bilingual comments (中英文注释) for key steps and assumptions.

## Delivery

- [ ] Record `ruff check .`, `pytest -q`, and `scripts/agent_pr_preflight.sh` in `openspec/_ops/task_runs/ISSUE-186.md`.
- [ ] Create PR with `Closes #186`, enable auto-merge, and backfill PR link in run log.

