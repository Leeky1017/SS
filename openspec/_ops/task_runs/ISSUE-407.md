# ISSUE-407
- Issue: #407
- Branch: task/407-state-machines
- PR: https://github.com/Leeky1017/SS/pull/408

## Goal
- Draw and validate SS core state machines (Job/Plan/Run/UploadSession/Worker) from code, and document them as Mermaid diagrams in OpenSpec.

## Status
- CURRENT: Drafted canonical state machine docs; running checks + preparing PR.

## Next Actions
- [ ] Run `ruff check .` and `pytest -q`.
- [ ] Run `openspec validate --specs --strict --no-interactive`.
- [ ] Open PR, run preflight, enable auto-merge.

## Plan
- Create/update canonical state machine documentation under `openspec/specs/` (docs/ is pointer-only).
- Cross-check domain transition logic against enums to find dead states/illegal transitions.
- Record evidence (commands + key outputs) and ship via PR with auto-merge.

## Runs
### 2026-01-12 00:00 Issue created
- Command: `gh issue create -t "SS: 系统核心状态机图（Mermaid）绘制与验证" -b "<body>"`
- Key output: `https://github.com/Leeky1017/SS/issues/407`

### 2026-01-12 00:00 Worktree setup
- Command: `scripts/agent_worktree_setup.sh "407" "state-machines"`
- Key output: `Worktree created: .worktrees/issue-407-state-machines`

### 2026-01-12 00:00 Rulebook task created
- Command: `rulebook task create issue-407-state-machines`
- Key output: `✅ Task issue-407-state-machines created successfully`

### 2026-01-12 00:00 Rulebook validate
- Command: `rulebook task validate issue-407-state-machines`
- Key output: `✅ Task issue-407-state-machines is valid`

### 2026-01-12 00:00 Draft state machine docs
- Command: `wc -l openspec/specs/ss-state-machine/state_machines.md`
- Key output: `222 openspec/specs/ss-state-machine/state_machines.md`
- Evidence:
  - `openspec/specs/ss-state-machine/state_machines.md`
  - `openspec/specs/ss-state-machine/spec.md`
  - `openspec/specs/ss-state-machine/README.md`
  - `docs/state_machines.md`

### 2026-01-12 00:00 Lint
- Command: `/home/leeky/work/SS/.venv/bin/ruff check .`
- Key output: `All checks passed!`

### 2026-01-12 00:00 Tests
- Command: `/home/leeky/work/SS/.venv/bin/pytest -q`
- Key output: `194 passed, 5 skipped`

### 2026-01-12 00:00 OpenSpec validate (strict)
- Command: `openspec validate --specs --strict --no-interactive`
- Key output: `Totals: 29 passed, 0 failed (29 items)`

### 2026-01-12 00:00 PR preflight
- Command: `scripts/agent_pr_preflight.sh`
- Key output: `OK: no overlapping files with open PRs`

### 2026-01-12 00:00 PR create
- Command: `gh pr create --title "docs: SS system state machine diagrams (#407)" --body "Closes #407 ..."`
- Key output: `https://github.com/Leeky1017/SS/pull/408`
