## 1. Implementation
- [ ] Add a repeatable benchmark for `FileWorkerQueue` throughput and record results in `openspec/_ops/task_runs/ISSUE-95.md`
- [ ] Define throughput targets/constraints and clarify current file-queue ceiling assumptions
- [ ] Document queue backend options (Postgres, Redis, RabbitMQ) and recommend a default
- [ ] Define rollout/migration steps and a validation checklist (correctness + performance)

## 2. Testing
- [ ] Run `ruff check .`
- [ ] Run `pytest -q`

## 3. Documentation
- [ ] Update `openspec/specs/ss-audit-remediation/task_cards/scalability__queue-throughput.md` checklist + add `## Completion`
- [ ] Ensure run log includes PR link and evidence
