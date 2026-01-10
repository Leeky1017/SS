## 1. Implementation
- [ ] 1.1 Create `openspec/specs/ss-production-e2e-audit-remediation/spec.md` with requirements + scenarios
- [ ] 1.2 Enumerate all audit findings (from `openspec/_ops/task_runs/ISSUE-274.md`) with priority and single fix direction
- [ ] 1.3 Create task cards under `openspec/specs/ss-production-e2e-audit-remediation/task_cards/` mapping to findings
- [ ] 1.4 Add run log `openspec/_ops/task_runs/ISSUE-289.md` and record key command outputs (append-only)

## 2. Testing
- [ ] 2.1 Run `openspec validate --specs --strict --no-interactive`
- [ ] 2.2 Run `ruff check .` and `pytest -q`
- [ ] 2.3 Run `scripts/agent_pr_preflight.sh`

## 3. Documentation
- [ ] 3.1 Ensure the spec is the only authoritative doc for remediation scope (no parallel docs under `docs/`)
