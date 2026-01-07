# ISSUE-71

- Issue: #71
- Branch: task/71-taskcard-hygiene
- PR: <fill-after-created>

## Plan
- Audit roadmap issue status vs task cards
- Mark completed task cards with checklist + completion summary
- Update delivery docs to enforce this hygiene

## Runs
### 2026-01-07 Create issue
- Command:
  - `gh issue create -t "[OPS] TASKCARD-HYGIENE: Audit completions and archive specs" -b "<body>"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/71`

### 2026-01-07 Setup worktree
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 71 taskcard-hygiene`
- Key output:
  - `Worktree created: .worktrees/issue-71-taskcard-hygiene`
  - `Branch: task/71-taskcard-hygiene`

### 2026-01-07 Audit roadmap issues vs task cards
- Command:
  - `gh issue view <N> --json state,closedAt,url,title` (N in 16,17,18,19,20,21,22,23,24,25,26,27,36)
  - `find openspec/specs -maxdepth 2 -type d -name task_cards`
- Key output:
  - Roadmap issues #16-#27 and #36 are `CLOSED`
  - Task cards existed but acceptance checklists were not marked complete

### 2026-01-07 Fill missing PR links in run logs
- Command:
  - `gh pr list --state merged --search "closes #18" --json url --jq '.[0].url'`
  - `gh pr list --state merged --search "closes #22" --json url --jq '.[0].url'`
  - `gh pr list --state merged --search "closes #23" --json url --jq '.[0].url'`
  - `gh pr list --state merged --search "#26" --json url --jq '.[0].url'`
- Key output:
  - Backfilled `PR:` for `openspec/_ops/task_runs/ISSUE-18.md`, `ISSUE-22.md`, `ISSUE-23.md`, `ISSUE-26.md`

### 2026-01-07 Mark task cards completed
- Command:
  - `git grep -n \"## Acceptance checklist\" openspec/specs/*/task_cards/*.md`
- Key output:
  - Acceptance checklists marked `[x]` and `## Completion` added with PR link + summary
  - Roadmap task cards index updated to `[x]` status

### 2026-01-07 Spec archive audit
- Result:
  - No additional spec under `openspec/specs/` meets archive criteria (core contracts referenced by `ss-constitution` remain active)

### 2026-01-07 Local verification
- Command:
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest -q`
- Key output:
  - `All checks passed!`
  - `56 passed`

### 2026-01-07 PR preflight
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
