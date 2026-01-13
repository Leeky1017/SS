# Proposal: issue-450-draft-preview-enhance

## Why
Draft preview currently only extracts `outcome_var`, `treatment_var`, and `controls`, so it cannot represent common econometric requirements like panel dimensions, fixed effects, clustering, interaction terms (DID), or instruments (IV). Downstream planning/do-file generation needs these structured hints to generate correct Stata code.

## What Changes
- Add a versioned draft preview output schema (v2) with fields for `time_var`, `entity_var`, `cluster_var`, `fixed_effects`, `interaction_terms`, `instrument_var`, and `analysis_hints`.
- Add `build_draft_preview_prompt_v2()` to instruct the LLM (econometrics expert role) to output JSON matching the v2 schema.
- Add `parse_draft_preview_v2()` to validate and parse v2 output, with fallback to v1 JSON outputs.
- Add unit tests for panel, DID, IV, and edge cases.
- Update canonical spec `openspec/specs/ss-llm-brain/spec.md` to document the v2 schema.

## Impact
- Affected specs: `openspec/specs/ss-llm-brain/spec.md`
- Affected code: `src/domain/draft_preview_llm.py`, `src/domain/draft_service.py`, `tests/unit/test_draft_preview_llm.py`
- Breaking change: NO (v1 JSON outputs remain supported)
- User benefit: Draft preview can capture FE/cluster/interaction/IV structure for more accurate downstream analysis plans.
