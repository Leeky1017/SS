# Proposal: issue-267-llm-draft-vars

## Why
Launch readiness requires that Step 3 draft preview can reflect the user's requirement by extracting `outcome_var` / `treatment_var` / `controls` from the LLM output (Claude Opus 4.5), instead of always leaving them `null` and forcing manual patch.

## What Changes
- Build a schema-bound `draft_preview` prompt (requirement + dataset column candidates) requesting JSON-only output.
- Parse JSON LLM responses into structured `Draft` fields (`text`, `outcome_var`, `treatment_var`, `controls`, `default_overrides`).
- Preserve existing behavior for stub/fallback/non-JSON responses (no hard failure).

## Impact
- Affected specs: `openspec/specs/ss-frontend-backend-alignment/spec.md`, `openspec/specs/frontend-stata-proxy-extension/spec.md`
- Affected code: `src/domain/draft_service.py`, new domain helpers for prompt + parsing
- Breaking change: NO (non-JSON output still supported)
- User benefit: Draft preview shows variables aligned with requirement (less manual input, clearer UI)
