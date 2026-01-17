# Proposal: issue-513-ss-ux-remediation

## Why
The current UX audit spec (`ss-frontend-ux-audit`) is legacy and needs to be removed to avoid maintaining two overlapping documentation systems. We need a single, up-to-date OpenSpec home for the full UX remediation scope (frontend + backend + E2E), with per-item task cards that are independently executable and acceptance-testable.

## What Changes
REMOVED:
- `openspec/specs/ss-frontend-ux-audit/` (legacy UX audit spec folder).

ADDED:
- `openspec/specs/ss-ux-remediation/` OpenSpec with:
  - `spec.md` (scope/priorities/acceptance)
  - design docs (frontend architecture, backend API enhancements, UX patterns)
  - task cards: FE-001..FE-064, BE-001..BE-009, E2E-001

## Impact
- Affected specs: `openspec/specs/ss-frontend-ux-audit/spec.md` (removed), `openspec/specs/ss-ux-remediation/spec.md` (added)
- Affected code: none (docs/spec-only)
- Breaking change: NO
- User benefit: A clear, maintainable UX remediation backlog with per-item acceptance criteria and explicit dependencies.
