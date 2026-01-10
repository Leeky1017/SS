# Proposal — ISSUE-280 (Phase 4.10 Finance TK01–TK20)

## Objective
- Make `TK01`–`TK20` templates runnable under the Stata 18 smoke-suite harness with contract-compliant `SS_EVENT|k=v` anchors.

## Scope
- Update `assets/stata_do_library/do/TK*.do` for runtime correctness, defensive checks, and anchor normalization.
- Add smoke-suite manifest for this scope and record evidence reports.

## Non-goals
- Finance-method best-practice upgrades beyond “runs + auditable” (Phase 5).

