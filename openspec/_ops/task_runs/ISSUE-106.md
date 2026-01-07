# ISSUE-106

- Issue: #106
- Branch: task/106-distributed-tracing
- PR: https://github.com/Leeky1017/SS/pull/118

## Plan
- Define trace propagation + config
- Implement API/worker instrumentation + log correlation
- Add tests + run ruff/pytest/openspec validate

## Runs
### 2026-01-07 07:00 Setup: issue + worktree
- Command:
  - `gh issue create -t "[SS-AUDIT-OPS] Distributed tracing (end-to-end)" -b "<context + acceptance>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "106" "distributed-tracing"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/106`
  - `Worktree created: .worktrees/issue-106-distributed-tracing`
  - `Branch: task/106-distributed-tracing`
- Evidence:
  - `rulebook/tasks/issue-106-distributed-tracing/proposal.md`
  - `rulebook/tasks/issue-106-distributed-tracing/tasks.md`
  - `openspec/specs/ss-observability/spec.md`

### 2026-01-07 07:19 Validate: lint + tests + specs
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/python -m pip install -U pip`
  - `.venv/bin/python -m pip install -e ".[dev]"`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `All checks passed!`
  - `78 passed in 2.62s`
  - `Totals: 17 passed, 0 failed (17 items)`

### 2026-01-07 07:42 Closeout: tracing config + span map
- Config (deployment):
  - `SS_TRACING_ENABLED=1`
  - `SS_TRACING_EXPORTER=otlp` (or `console` for local)
  - `SS_TRACING_OTLP_ENDPOINT=http://localhost:4318/v1/traces`
  - `SS_TRACING_SAMPLE_RATIO=1.0`
- Span names:
  - `ss.job.create`
  - `ss.job.enqueue`
  - `ss.queue.claim`
  - `ss.llm.draft_preview`
  - `ss.stata.run`
- Result:
  - PR merged: https://github.com/Leeky1017/SS/pull/118
