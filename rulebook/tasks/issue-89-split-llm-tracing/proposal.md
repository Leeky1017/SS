# Proposal: issue-89-split-llm-tracing

## Why
Repo hard constraint requires each file `< 300` lines. `src/infra/llm_tracing.py` is currently above that limit.

## What Changes
- Split retry/logging helpers out of `src/infra/llm_tracing.py` into a small infra helper module.
- Keep runtime behavior and tests unchanged.

## Impact
- Affected code: `src/infra/llm_tracing.py`, new helper module
- Breaking change: NO

