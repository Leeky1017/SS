## 1. Harness + Evidence
- [ ] 1.1 Add TP/TQ smoke-suite manifest (fixtures + params + deps)
- [ ] 1.2 Create venv + install dev deps (`pip install -e '.[dev]'`)
- [ ] 1.3 Run Stata 18 smoke-suite harness; save JSON report into `rulebook/.../evidence/`
- [ ] 1.4 Iterate fixes until report shows 0 `failed` for all in-scope templates

## 2. Anchors + Style
- [ ] 2.1 Normalize legacy anchors to pipe-delimited `SS_EVENT|k=v` (remove `SS_*:` variants)
- [ ] 2.2 Ensure missing deps fail fast with `SS_DEP_MISSING` + `SS_RC|code=199|...|severity=fail`
- [ ] 2.3 Ensure convergence/fragile failure modes emit explicit `warn/fail` via `SS_RC` with context

## 3. Validation
- [ ] 3.1 `ruff check .`
- [ ] 3.2 `pytest -q`
- [ ] 3.3 `openspec validate --specs --strict --no-interactive`

## 4. Delivery
- [ ] 4.1 Update run log: `openspec/_ops/task_runs/ISSUE-354.md`
- [ ] 4.2 Run `scripts/agent_pr_preflight.sh`
- [ ] 4.3 Open PR and enable auto-merge; verify PR is `MERGED`
- [ ] 4.4 Sync controlplane `main` and cleanup worktree

