# ISSUE-68

- Issue: #68
- Branch: task/68-spec-archive
- PR: https://github.com/Leeky1017/SS/pull/69

## Plan
- Identify completed specs under `openspec/specs/`
- Move confirmed specs to `openspec/specs/archive/`
- Update pointers and validate locally

## Runs
### 2026-01-07 Create issue
- Command:
  - `gh issue create -t "[OPS] SPEC-ARCHIVE: Archive completed OpenSpec specs" -b "<body>"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/68`

### 2026-01-07 Setup worktree
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 68 spec-archive`
- Key output:
  - `Worktree created: .worktrees/issue-68-spec-archive`
  - `Branch: task/68-spec-archive`

### 2026-01-07 Inventory specs
- Command:
  - `find openspec/specs -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort`
- Key output:
  - `openspec-officialize` + `stata-service-legacy-analysis` identified as non-core process/reference specs

### 2026-01-07 Verify completion signals (officialize spec)
- Command:
  - `test -f openspec/project.md`
  - `test -f openspec/AGENTS.md`
  - `test -d openspec/changes/archive`
  - `rg -n "openspec validate --specs --strict --no-interactive" .github/workflows/ci.yml`
- Key output:
  - Root layout present; CI runs strict OpenSpec validation

### 2026-01-07 Archive completed specs
- Command:
  - `git mv openspec/specs/openspec-officialize openspec/specs/archive/openspec-officialize`
  - `git mv openspec/specs/stata-service-legacy-analysis openspec/specs/archive/stata-service-legacy-analysis`
- Evidence:
  - `openspec/specs/archive/openspec-officialize/spec.md`
  - `openspec/specs/archive/stata-service-legacy-analysis/spec.md`

### 2026-01-07 Update pointers
- Command:
  - `rg -n "openspec/specs/(openspec-officialize|stata-service-legacy-analysis)" .`
- Key output:
  - No remaining references to the old locations
- Evidence:
  - `openspec/specs/ss-roadmap/README.md`
  - `docs/legacy_analysis.md`

### 2026-01-07 Local verification
- Command:
  - `python3 -m venv .venv`
  - `. .venv/bin/activate && pip install -e '.[dev]'`
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

### 2026-01-07 Open PR
- Command:
  - `git push -u origin HEAD`
  - `gh pr create --base main --head task/68-spec-archive --title "chore: archive completed specs (#68)" --body "Closes #68 ..."`
- Key output:
  - `https://github.com/Leeky1017/SS/pull/69`
