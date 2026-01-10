# Proposal: Phase 5.11 TL templates enhancement

## Summary
- Upgrade `assets/stata_do_library/do/TL01`–`TL15` to add best-practice guidance, strengthen input validation and explicit `SS_RC` reporting, and add bilingual (EN/ZH) comments for interpretation.

## Non-goals
- No new external dependencies; SSC commands removed where feasible.
- No taxonomy/index redesign beyond what is required to keep meta/do consistent.

## Risks
- Some best-practice diagnostics may increase runtime or require additional variables; mitigate via opt-in placeholders and `warn` vs `fail` handling.

