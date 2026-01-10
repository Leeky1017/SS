# Proposal: issue-328-prod-e2e-r011-template-selection

## Summary

MODIFIED:
- `/v1` draft preview selects a real do-template via `DoTemplateSelectionService` and archives auditable selection evidence (stage1/candidates/stage2).
- Persist `selected_template_id` onto the job record for plan freeze to consume.
- Remove hard-coded `template_id="stub_descriptive_v1"` from the `/v1` chain.

## Impact

- Template selection becomes explainable, reproducible, and non-hardcoded in the production `/v1` journey.
- Unblocks downstream remediation tasks that need selected template meta (e.g. explicit plan contract).
