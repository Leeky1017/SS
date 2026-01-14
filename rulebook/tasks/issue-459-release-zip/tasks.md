## 1. Implementation
- [ ] 1.1 Add `scripts/ss_release_zip.sh` (git-archive based)
- [ ] 1.2 Ignore `release/*.zip` outputs
- [ ] 1.3 Add run log `openspec/_ops/task_runs/ISSUE-459.md`

## 2. Testing
- [ ] 2.1 Run `scripts/ss_release_zip.sh` and confirm zip output
- [ ] 2.2 Run `ruff check .` and `pytest -q`
- [ ] 2.3 Run `openspec validate --specs --strict --no-interactive`

## 3. Documentation
- [ ] 3.1 N/A (no user-facing docs changes required)
