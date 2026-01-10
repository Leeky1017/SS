# Proposal: issue-305-controlplane-guard

## Why
- Parallel worktrees depend on a clean controlplane `main`; when controlplane is dirty, sync/cleanup is blocked and risks cross-task contamination.

## What Changes
- Add a fail-fast “controlplane clean” guard to PR preflight.
- Make worktree setup run controlplane sync first and refuse to run outside repo root.
- Improve sync error output to show which files made controlplane dirty and how to recover.

## Impact
- Affected specs: none
- Affected code:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh`
  - `scripts/agent_pr_preflight.py`
- Breaking change: NO (only tightens agent workflow safety)
- User benefit: fewer cross-task footguns; earlier, actionable failures when controlplane is accidentally modified.
