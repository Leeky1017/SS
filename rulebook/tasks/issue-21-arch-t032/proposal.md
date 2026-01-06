# Proposal: issue-21-arch-t032

## Summary

- Persist every LLM call as auditable artifacts: prompt/response/meta with redaction.
- Update `job.json` `artifacts_index` so downstream APIs/workers can discover LLM traces.
- Cover both success and failure paths with tests.

## Changes

### ADDED

- LLM traced client (writes artifacts + redacts sensitive values).

### MODIFIED

- Draft preview flow to persist LLM artifacts on both success and failure.
- OpenSpec LLM Brain spec to define artifacts layout and redaction rules.

