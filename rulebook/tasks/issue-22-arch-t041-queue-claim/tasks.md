# Tasks: issue-22-arch-t041-queue-claim

## 1. Spec-first
- [ ] 1.1 Update `openspec/specs/ss-worker-queue/spec.md` with lease/expiry requirement

## 2. Implementation
- [ ] 2.1 Add domain queue port for claim/ack/release
- [ ] 2.2 Add infra file-based implementation using atomic rename
- [ ] 2.3 Define explicit lease TTL + reclaim behavior

## 3. Testing
- [ ] 3.1 Add unit tests for concurrent claim (single winner)
- [ ] 3.2 Add unit tests for expiry reclaim
- [ ] 3.3 Run `ruff check .` and `pytest -q` and record outputs in `openspec/_ops/task_runs/ISSUE-22.md`

## 4. Delivery
- [ ] 4.1 Ensure `openspec/_ops/task_runs/ISSUE-22.md` is present and updated
- [ ] 4.2 Open PR with `Closes #22` and enable auto-merge

