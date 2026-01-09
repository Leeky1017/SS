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

### Requirement: PR preflight checks conflicts and roadmap dependencies

Before creating a PR or enabling auto-merge, the agent MUST run the preflight check:
- `scripts/agent_pr_preflight.sh`

The preflight MUST:
- detect file overlap with other open PRs (conflict risk)
- detect blocked dependencies from the roadmap execution plan:
  - `openspec/specs/ss-roadmap/execution_plan.md`

If preflight reports problems (non-zero exit code), the agent MUST either:
- resolve/coordinate (preferred), or
- keep the PR as draft and wait until unblocked, or
- proceed with `--force` / `--skip-preflight` and record the rationale + output in `openspec/_ops/task_runs/ISSUE-N.md`.

#### Scenario: Preflight surfaces file overlap with open PRs
- **WHEN** running `scripts/agent_pr_preflight.sh` on a task branch
- **THEN** it prints overlapping file paths and the corresponding open PR numbers

#### Scenario: Preflight surfaces blocked roadmap dependencies
- **WHEN** running `scripts/agent_pr_preflight.sh` on a task branch with hard dependencies
- **THEN** it prints the dependency issues and their states, and exits non-zero if any are still open

### Requirement: Auto-merge completion MUST be verified and cannot be silently abandoned

After enabling auto-merge and all required checks are green, the agent MUST verify the PR has actually merged (`mergedAt != null`).

If the PR is not merged, the agent MUST treat this as a blocker and MUST NOT stop as if delivery is complete.
The agent MUST:
- determine and surface the blocker (e.g., `reviewDecision=REVIEW_REQUIRED`, `mergeStateStatus=BEHIND`, merge conflicts, merge queue),
- record the blocker + next action in the run log `openspec/_ops/task_runs/ISSUE-N.md`,
- and comment on the PR (or otherwise notify) so it cannot be missed.

Notes:
- A PR author cannot approve their own PR. To keep SS delivery fully autonomous (no human intervention), the repository MUST allow the agent to bypass review requirements via `gh pr merge --admin` (or provide an equivalent bot/app that can approve/merge).

#### Scenario: Auto-merge is enabled but PR is blocked by required review
- **GIVEN** auto-merge is enabled and all required checks are green
- **WHEN** the PR reports `reviewDecision=REVIEW_REQUIRED`
- **THEN** the agent records a blocker and attempts an admin merge (or bot-based merge) instead of assuming the PR will merge

#### Scenario: Auto-merge is enabled but PR is behind base
- **GIVEN** auto-merge is enabled and all required checks are green
- **WHEN** the PR reports `mergeStateStatus=BEHIND`
- **THEN** the agent records a blocker and rebases/pushes (or coordinates) before continuing
