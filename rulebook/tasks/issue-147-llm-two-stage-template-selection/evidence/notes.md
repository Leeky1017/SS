# Notes: issue-147-llm-two-stage-template-selection

## Decisions

- Use `DO_LIBRARY_INDEX.json` `families` + `tasks` as the canonical runtime source for `FamilySummary` / `TemplateSummary` (avoid duplicating taxonomy).

## Open Questions

- Should selection evidence live under `artifacts/do_template/` (job-level) or `runs/<run_id>/artifacts/` (run-level)? Current implementation targets job-level artifacts for plan-time auditability.

## Later

- Consider adding a dedicated API endpoint to trigger selection and return the chosen `template_id` (if needed for UX).

