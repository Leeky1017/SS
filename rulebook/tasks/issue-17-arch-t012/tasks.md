# Tasks: issue-17-arch-t012

- [ ] Update OpenSpec state machine spec with explicit states/transitions
- [ ] Implement domain state machine guard (legal + illegal transitions)
- [ ] Implement idempotency key calculation (fingerprint + normalized requirement + plan revision)
- [ ] Make create/transition flows idempotent where appropriate
- [ ] Add unit tests: legal transitions, illegal transitions, idempotent repeats
- [ ] Run `ruff check .` and `pytest -q` and record outputs in `openspec/_ops/task_runs/ISSUE-17.md`
- [ ] Open PR with `Closes #17` and enable auto-merge

