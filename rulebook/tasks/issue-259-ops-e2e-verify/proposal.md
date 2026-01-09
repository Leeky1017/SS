# Proposal: issue-259-ops-e2e-verify

## Why
- SS is approaching go-live; we need an auditable, end-to-end verification that a real user can complete the v1 loop (redeem → upload → preview → draft/patch/confirm → run → artifacts download) and that the LLM + Stata runtime are correctly configured.

## What Changes
- Run the full HTTP user journey against a locally started SS API + worker, using the configured LLM provider and **Claude Opus 4.5**.
- Record every key command + output + artifact checks in `openspec/_ops/task_runs/ISSUE-259.md` (redacting secrets).
- If blockers are found, implement minimal fixes and add regression coverage.

## Impact
- Affected code: `src/config.py` (LLM model id normalization), `src/domain/do_file_generator.py` (CSV import).
- Affected docs: run log only (`openspec/_ops/task_runs/ISSUE-259.md`); avoid new docs under `docs/`.
- User benefit: confidence that SS “can run, can understand, can produce”.

