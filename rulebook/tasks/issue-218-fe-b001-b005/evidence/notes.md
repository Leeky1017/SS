# Notes: issue-218-fe-b001-b005

## Context
- Spec: `openspec/specs/frontend-stata-proxy-extension/spec.md`
- Legacy references:
  - `legacy/stata_service/frontend/src/components/DraftPreview.tsx`
  - `legacy/stata_service/frontend/src/components/ConfirmationStep.tsx`

## UX decisions (keep minimal)
- Collapsible panels use `<details>` to avoid new component system.
- Confirm downgrade risk uses an in-page modal (no `window.confirm`).
- Draft preview request supports 202 pending polling UX; backend may still return 200 only.

## Later (out of scope)
- Data source selection (multi-sheet Excel) parity with legacy UI.
- Expert suggestions feedback + default overrides editor (v1 allows empty objects).
