# Proposal: Phase 5.12 TM templates enhancement

## Summary
- Upgrade `assets/stata_do_library/do/TM01`–`TM15` to add best-practice guidance, strengthen input validation and explicit `SS_RC` reporting, and add bilingual (EN/ZH) comments for interpretation.
- Remove SSC dependencies where feasible (notably `metan`/`metafunnel`) using Stata 18 built-in `meta` suite.

## Non-goals
- No new external dependencies; avoid introducing new SSC packages.
- No taxonomy/index redesign beyond what is required to keep meta/do consistent.

## Risks
- Meta-analysis commands vary across Stata editions; mitigate by sticking to documented Stata 18 `meta` workflow and failing fast with clear `SS_RC` when commands are unavailable.

