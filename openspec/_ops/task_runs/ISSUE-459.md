# ISSUE-459
- Issue: #459
- Branch: task/459-release-zip
- PR: <fill-after-created>

## Plan
- Add a reproducible zip packaging script.
- Ignore generated release zip artifacts.
- Generate the zip into `release/` on `main`.

## Runs
### 2026-01-14 07:58 Create Issue
- Command: `gh issue create -t "[RELEASE] Package latest SS as zip" -b "..."`
- Key output: `https://github.com/Leeky1017/SS/issues/459`
- Evidence: N/A

### 2026-01-14 07:58 Create worktree
- Command: `scripts/agent_worktree_setup.sh 459 release-zip`
- Key output: `Worktree created: .worktrees/issue-459-release-zip`
- Evidence: N/A

### 2026-01-14 07:58 Rulebook task scaffold
- Command: `rulebook task create issue-459-release-zip && rulebook task validate issue-459-release-zip`
- Key output: `✅ Task issue-459-release-zip is valid`
- Evidence: `rulebook/tasks/issue-459-release-zip/`

### 2026-01-14 08:01 Generate zip (worktree smoke test)
- Command: `scripts/ss_release_zip.sh`
- Key output: `Wrote: release/SS-20260114-000123-gf10bbdf.zip`
- Evidence: `release/SS-20260114-000123-gf10bbdf.zip`
