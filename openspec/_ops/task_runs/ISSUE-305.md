# ISSUE-305
- Issue: #305 https://github.com/Leeky1017/SS/issues/305
- Branch: task/305-controlplane-guard
- PR: https://github.com/Leeky1017/SS/pull/308

## Goal
- Add a fail-fast guard to enforce “controlplane main stays clean” in the standard delivery flow, reducing the chance of cross-task contamination when multiple worktrees run in parallel.

## Status
- CURRENT: Implementing guards in agent scripts (setup + preflight + sync messaging).

## Next Actions
- [ ] Implement guard changes in `scripts/agent_*`.
- [ ] Add run log evidence (commands + key output).
- [ ] Run quick local validation (`python -m py_compile`, basic script smoke).
- [ ] Open PR and enable auto-merge; verify `MERGED`.

## Decisions Made
- 2026-01-10: Enforce via agent scripts (setup + preflight) rather than git hooks to avoid relying on local hook configuration.

## Errors Encountered

## Runs
### 2026-01-10 Setup: Issue + worktree
- Command:
  - `gh issue create -t "[OPS] Worktree guard: block dirty controlplane" -b "<body omitted>"`
  - `scripts/agent_worktree_setup.sh "305" "controlplane-guard"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/305`
  - `Worktree created: .worktrees/issue-305-controlplane-guard`
  - `Branch: task/305-controlplane-guard`
- Evidence:
  - (this file)

### 2026-01-10 Implement: add controlplane guards
- Command:
  - Edit: `scripts/agent_controlplane_sync.sh`
  - Edit: `scripts/agent_worktree_setup.sh`
  - Edit: `scripts/agent_pr_preflight.py`
- Key output:
  - `agent_controlplane_sync.sh` now prints `git status --porcelain=v1` and a remediation hint when controlplane is dirty.
  - `agent_worktree_setup.sh` now enforces repo-root execution and runs `agent_controlplane_sync.sh` first.
  - `agent_pr_preflight.py` now fails fast when controlplane is dirty.
- Evidence:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh`
  - `scripts/agent_pr_preflight.py`

### 2026-01-10 Validation: python compile + script smoke
- Command:
  - `python3 -m py_compile scripts/agent_pr_preflight.py`
  - `bash -n scripts/agent_controlplane_sync.sh scripts/agent_worktree_setup.sh`
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `agent_pr_preflight.sh` succeeds with clean controlplane.
- Evidence:
  - (this file)

### 2026-01-10 Validation: guard triggers on dirty controlplane
- Command:
  - Create a temporary untracked file in controlplane: `echo tmp > /home/leeky/work/SS/.controlplane_guard_tmp`
  - Run: `scripts/agent_pr_preflight.sh` (from the issue worktree)
  - Cleanup: `rm -f /home/leeky/work/SS/.controlplane_guard_tmp`
- Key output:
  - Preflight fails with exit code `5` and prints the controlplane dirty list.
- Evidence:
  - (this file)

### 2026-01-10 Recovery: restore clean controlplane
- Command:
  - `git -C /home/leeky/work/SS status --porcelain=v1`
  - `git -C /home/leeky/work/SS stash push -u -m "WIP: misplaced rulebook task dir issue-299 (controlplane guard)"`
- Key output:
  - Controlplane returned to clean state so `agent_controlplane_sync.sh` can run.
- Evidence:
  - (this file)
