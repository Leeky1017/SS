# Spec: ss-delivery-workflow

## Purpose

Define SS collaboration and delivery workflow as enforceable gates (Issue → PR → Checks → Auto-merge), so development remains auditable and spec-first.

## Requirements

### Requirement: Every change is Issue-gated and PR-delivered

All changes MUST be tracked by a GitHub Issue `#N` and MUST be merged via a PR that follows SS delivery hard gates:
- branch name: `task/<N>-<slug>`
- every commit message contains `(#N)`
- PR body contains `Closes #N`
- PR includes run log: `openspec/_ops/task_runs/ISSUE-N.md`
- required checks are green: `ci` / `openspec-log-guard` / `merge-serial`
- auto-merge is enabled

#### Scenario: PR gate is enforced by checks
- **WHEN** a PR is opened for Issue `#N`
- **THEN** `openspec-log-guard` fails if branch/commit/PR body/run log rules are violated

### Requirement: OpenSpec strict validation is a required gate

All active specs MUST pass:
- `openspec validate --specs --strict --no-interactive`

#### Scenario: Specs validate in strict mode
- **WHEN** running `openspec validate --specs --strict --no-interactive`
- **THEN** the command exits with code `0`

### Requirement: Run log is the evidence ledger

Each Issue MUST have a run log at `openspec/_ops/task_runs/ISSUE-N.md` that records key commands, outputs, and evidence paths.

#### Scenario: A PR includes the run log file
- **WHEN** reviewing a PR for Issue `#N`
- **THEN** the PR includes `openspec/_ops/task_runs/ISSUE-N.md`

### Requirement: Worktrees are cleaned after merge

After a PR is merged and the controlplane `main` is synced to `origin/main`, the corresponding worktree directory under `.worktrees/issue-<N>-<slug>` MUST be removed to avoid stale state and accidental reuse.

#### Scenario: Worktree cleanup command succeeds
- **WHEN** running `scripts/agent_worktree_cleanup.sh <N> <slug>` from the controlplane root
- **THEN** the worktree directory `.worktrees/issue-<N>-<slug>` no longer exists
