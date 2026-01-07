# Proposal: ISSUE-66 Audit remediation spec + task cards

## Summary
- ADDED: `Audit/` reports to the repo (inputs for remediation)
- ADDED: `openspec/specs/ss-audit-remediation/` (requirements + prioritized task cards)
- ADDED: `openspec/_ops/task_runs/ISSUE-66.md` (auditable run log for this delivery)

## Rationale
Audit findings are currently “report-only” and not represented as executable OpenSpec work. This change turns the audit into a single canonical remediation spec pack so future delivery can be issue-gated, testable, and trackable.

## Impact
- Affected specs: `openspec/specs/ss-audit-remediation/`
- Affected code: none (docs/spec only)
- Breaking change: no
