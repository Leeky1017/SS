# Tasks: issue-433-admin-console

## Spec-first

- [x] Add OpenSpec spec for admin console surface + auth model
- [x] Add Rulebook delta spec (`rulebook/tasks/issue-433-admin-console/specs/*/spec.md`)

## Implementation

- [x] Implement admin auth (login/logout + bearer enforcement)
- [x] Implement admin token management (create/list/revoke/delete)
- [x] Implement Task Code management (batch create/list/revoke/delete) + redeem integration
- [x] Implement admin job monitoring (list/details/retry/download artifacts)
- [x] Implement system status (health/queue depth/worker status)
- [x] Implement frontend `/admin` UI (login + pages + tenant switch)

## Tests

- [x] Unit tests for admin token store + auth service
- [x] Unit tests for Task Code store + redeem state transitions
- [x] Unit tests for admin job listing/details/retry and artifact download safety

## Delivery

- [ ] Record `ruff check .`, `mypy`, `pytest -q` in `openspec/_ops/task_runs/ISSUE-433.md`
- [ ] Run `scripts/agent_pr_preflight.sh` and record output in `openspec/_ops/task_runs/ISSUE-433.md`
- [ ] Create PR with body containing `Closes #433`, enable auto-merge, and backfill PR link in `openspec/_ops/task_runs/ISSUE-433.md`
