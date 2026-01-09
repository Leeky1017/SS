# ISSUE-258
- Issue: #258
- Branch: task/258-p57-causal-tg
- PR: https://github.com/Leeky1017/SS/pull/265

## Plan
- Audit TG01–TG25 for best practices + SSC deps
- Upgrade templates (PSM/IV/DID/RDD/SCM/LATE/MTE) with diagnostics + bilingual notes
- Re-run smoke suite + local checks and link evidence

## Runs

### 2026-01-09 Audit + dependency decisions
- Evidence: `rulebook/tasks/issue-258-p57-causal-tg/evidence/tg01-tg25_audit.md`

### 2026-01-09 Regenerate do-library index
- Command: `python3 scripts/regenerate_do_library_index.py`
- Evidence: `assets/stata_do_library/DO_LIBRARY_INDEX.json`

### 2026-01-09 Local env + checks
- Command: `python3 -m venv .venv && . .venv/bin/activate && python -m pip install -U pip && python -m pip install -e '.[dev]'`
- Key output: Installed project deps + dev deps (incl. `pydantic`, `pytest`, `ruff`)
- Command: `ruff check .`
- Key output: `All checks passed!`
- Command: `pytest -q`
- Key output: `159 passed, 5 skipped`

### 2026-01-09 Smoke-suite manifest alignment
- Key output: Updated `assets/stata_do_library/smoke_suite/manifest.issue-241.tg01-tg25.1.0.json` dependencies to match updated TG meta (test guard)
- Evidence: `assets/stata_do_library/smoke_suite/manifest.issue-258.tg01-tg25.1.1.json`
