# ISSUE-95

- Issue: #95
- Branch: task/95-queue-throughput
- PR: <fill-after-created>

## Plan
- Measure file queue throughput ceiling
- Define throughput targets + constraints
- Document scale options + rollout steps

## Runs

### 2026-01-07 13:55 Issue + worktree setup
- Command:
  - `gh issue create -t "[ROUND-00-AUDIT-A] AUDIT-S010: Queue throughput constraints + scale path" -b "<body>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "95" "queue-throughput"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/95`
  - `Worktree created: .worktrees/issue-95-queue-throughput`
  - `Branch: task/95-queue-throughput`

### 2026-01-07 14:05 File queue throughput benchmark
- Command:
  - `python3 scripts/bench_queue_throughput.py --queued-jobs 2000 --workers 4`
  - `python3 scripts/bench_queue_throughput.py --queue-dir /tmp/ss-queue-bench-95-20000 --queued-jobs 20000 --claims 200 --workers 4`
- Key output:
  - `result queued_jobs=2000 claims=2000 workers=4 elapsed_s=17.758 jobs_s=112.63 jobs_min=6757.6 claim_p95_ms=69.40`
  - `result queued_jobs=20000 claims=200 workers=4 elapsed_s=40.147 jobs_s=4.98 jobs_min=298.9 claim_p95_ms=931.41`
- Evidence:
  - `scripts/bench_queue_throughput.py`

### 2026-01-07 14:08 Spec artifacts
- Evidence:
  - `openspec/specs/ss-worker-queue/throughput.md`
  - `openspec/specs/ss-worker-queue/decision.md`
  - `openspec/specs/ss-worker-queue/migration.md`

### 2026-01-07 14:12 Validation
- Command:
  - `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `All checks passed!`
  - `66 passed`
  - `Totals: 17 passed, 0 failed (17 items)`
