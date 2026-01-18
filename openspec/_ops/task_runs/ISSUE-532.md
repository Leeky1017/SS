# ISSUE-532
- Issue: #532
- Branch: task/532-be-005-auxiliary-file-sheets
- PR: <fill-after-created>

## Plan
- Add dataset sheet selection endpoint for auxiliary Excel inputs
- Persist sheet options to manifest and surface in inputs preview
- Regenerate contract types and verify checks

## Runs
### 2026-01-18 setup
- Command: `scripts/agent_worktree_setup.sh "532" "be-005-auxiliary-file-sheets"`
- Key output: `Worktree created: .worktrees/issue-532-be-005-auxiliary-file-sheets`

### 2026-01-18 issue
- Command: `gh issue create -t "[WAVE-1] BE-005: Auxiliary file sheet selection" -b "<...>"`
- Key output: `https://github.com/Leeky1017/SS/issues/532`

### 2026-01-18 rulebook
- Command: `rulebook task create issue-532-be-005-auxiliary-file-sheets`
- Key output: `Task issue-532-be-005-auxiliary-file-sheets created successfully`

- Command: `rulebook task validate issue-532-be-005-auxiliary-file-sheets`
- Key output: `Task issue-532-be-005-auxiliary-file-sheets is valid`
