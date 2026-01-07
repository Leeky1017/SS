# Notes: issue-151-composition-adaptive-multi-data

## Decisions
- 2026-01-07: Treat this Issue as “spec/task breakdown upgrade” (no engine code changes in scope).

## Open Questions
- Do we want dataset-role inference to be fully LLM-driven, or partly deterministic (e.g., heuristics + LLM confirmation)?
- Should merge/append be expressed as first-class executor steps or as “template steps” (Stata do-files) to keep runner uniform?

## Later
- Add concrete examples (2-file merge, 3-file panel) once executor implementation work starts.
