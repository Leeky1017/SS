## 1. Verification (manual)
- [x] 1.1 Start API + worker with `.env` loaded and model pinned to Claude Opus 4.5.
- [x] 1.2 Execute v1 journey: redeem → upload → inputs preview → draft preview/patch/confirm → run → artifacts list/download.
- [x] 1.3 Verify state persistence: restart API and confirm job state/artifacts recover.

## 2. Optional edge cases
- [ ] 2.1 Ambiguous requirement → ensure `stage1_questions`/`open_unknowns` prompt clarification (not silent guessing).
- [x] 2.2 Missing key columns → ensure `open_unknowns` or structured errors surface the gap.
- [ ] 2.3 Retry after failure → confirm retry behavior is clear (worker attempts; API idempotency).

## 3. Engineering closeout
- [x] 3.1 Fix blockers + add regression tests.
- [x] 3.2 Run `ruff check .` and `pytest -q`.
- [ ] 3.3 Update `openspec/_ops/task_runs/ISSUE-259.md` with evidence and PR link.
