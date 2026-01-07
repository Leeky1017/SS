# Proposal: issue-155-phase-2-deduplicate-and-normalize-placeholders

## Why
The do-template library currently contains known exact duplicates and multiple placeholder variants, which increases maintenance cost and introduces selection drift for LLM-based retrieval.

## What Changes
- Remove first-wave exact duplicates by deleting redundant templates and keeping the canonical template IDs listed in the Phase 2 task card.
- Normalize high-frequency placeholder variants to a single canonical form across the remaining library.
- Regenerate `assets/stata_do_library/DO_LIBRARY_INDEX.json` from meta, and tighten lint gates to reject non-canonical placeholders.

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-2__deduplicate-and-normalize-placeholders.md`
- Affected code: `assets/stata_do_library/do/`, `assets/stata_do_library/do/meta/`, index generation + lint gate
- Breaking change: YES (template IDs removed from inventory/index)
- User benefit: smaller, less redundant selection set; consistent placeholder contract for rendering and linting
