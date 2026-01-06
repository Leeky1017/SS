# SS Project Constitution (OpenSpec)

This file is a high-level entrypoint for SS terms and non-negotiable boundaries.
The canonical detailed constraints live in:

- `openspec/specs/ss-constitution/spec.md`

## Project definition

SS is an LLM-driven Stata empirical analysis automation system that turns user inputs (data + requirement) into deterministic, auditable execution artifacts (plans, do-files, logs, tables/figures).

## Non-negotiable boundaries

- LLM output must be auditable and replayable via artifacts (no black box acceptance).
- Business logic lives in `src/domain/` and must not depend on FastAPI.
- External systems (LLM provider / Stata runner / storage) are isolated in `src/infra/` and injected explicitly.
- No dynamic proxies / implicit forwarding (`__getattr__`, module attribute proxy, delayed imports to hide cycles).

## Core terms (authoritative)

- `job`: The unit of analysis workflow; persisted as `jobs/<job_id>/job.json`.
- `artifact`: Any stored file or schema output associated with a job (inputs, prompts, plans, do-files, logs, exports).
- `llm_plan`: A structured plan to generate and execute Stata work (must be schema-bound, not free text).
- `run attempt`: One execution attempt for a job, identified by `run_id` and isolated under `jobs/<job_id>/runs/<run_id>/`.

