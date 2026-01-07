# Tasks: issue-96-job-store-sharding

## Spec-first

- [ ] Update `openspec/specs/ss-job-contract/spec.md` to define the sharded layout and lookup rules
- [ ] Update `openspec/specs/ss-job-contract/README.md` with shard function, examples, and ops implications

## Implementation

- [ ] Implement sharded job dir resolution (sharded preferred; legacy fallback)
- [ ] Ensure JobStore create/write uses sharded layout while keeping legacy jobs loadable
- [ ] Update run/artifact path helpers to use the sharded resolver (CLI + Stata runners + LLM tracing + artifacts download)

## Tests

- [ ] Add tests for sharded job path creation and run/artifact paths
- [ ] Add tests that legacy jobs remain loadable and writable after sharding change

## Delivery

- [ ] Record `ruff check .` and `pytest -q` in `openspec/_ops/task_runs/ISSUE-96.md`
- [ ] Run `scripts/agent_pr_preflight.sh` and record output in `openspec/_ops/task_runs/ISSUE-96.md`
- [ ] Create PR with body containing `Closes #96`, enable auto-merge, and backfill links in `openspec/_ops/task_runs/ISSUE-96.md`
- [ ] After merge, backfill `openspec/specs/ss-audit-remediation/task_cards/scalability__job-store-sharding.md` completion section and checkboxes

