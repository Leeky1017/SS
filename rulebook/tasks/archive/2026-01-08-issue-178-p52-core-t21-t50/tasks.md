# Tasks: issue-178-p52-core-t21-t50

## Spec-first

- [ ] Confirm Phase 4.2 completed for `T21`–`T50` baseline quality.
- [ ] Align with `openspec/specs/ss-do-template-optimization/spec.md` + Phase 5.2 task card acceptance.

## Implementation

- [ ] Add a best-practice review record to each template (`T21`–`T50`) with explicit decisions and rationale.
- [ ] Replace SSC deps with Stata 18 native equivalents where feasible (remove `estout/esttab`; use `putdocx`/`collect`/`putexcel` patterns).
- [ ] Strengthen error handling: validate inputs, avoid silent `capture` swallowing, emit `SS_RC` with severity `warn`/`fail`.
- [ ] Add bilingual comments (中英文注释) for key assumptions/steps (models, identification, diagnostics, outputs).
- [ ] Upgrade outputs (tables/reports/manifests) using Stata 18 native tools.

## Evidence

- [ ] Append key commands and outputs to `openspec/_ops/task_runs/ISSUE-178.md` (runs only append).

## Delivery

- [ ] Run `ruff check .` and `pytest -q`; record outputs in `openspec/_ops/task_runs/ISSUE-178.md`.
- [ ] Run `scripts/agent_pr_preflight.sh`; record output in `openspec/_ops/task_runs/ISSUE-178.md`.
- [ ] Create PR with body containing `Closes #178`, enable auto-merge, and backfill PR link in `openspec/_ops/task_runs/ISSUE-178.md`.
- [ ] After merge: backfill Phase 5.2 task card checkboxes and completion section with PR + run log link.

