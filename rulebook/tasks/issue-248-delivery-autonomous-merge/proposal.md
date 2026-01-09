# Proposal: issue-248-delivery-autonomous-merge

## Why
SS delivery relies on auto-merge, but a PR can remain unmerged even when checks are green (e.g., review gate, behind base, merge conflicts, or merge queue), which risks silent abandonment and broken end-to-end automation.

## What Changes
- Strengthen `scripts/agent_pr_automerge_and_sync.sh` to deterministically verify the PR is actually merged and handle common blockers (auto-rebase when behind; admin merge attempt when review is required).
- Update delivery docs/specs to make “verify mergedAt” a hard gate and require repository settings that allow fully autonomous merges.

## Impact
- Affected specs: `openspec/specs/ss-delivery-workflow/spec.md`
- Affected code: `scripts/agent_pr_automerge_and_sync.sh`, `AGENTS.md`
- Breaking change: NO
- User benefit: Agent can complete Issue→PR→Merge→Sync→Cleanup without human intervention or silent stalls.
