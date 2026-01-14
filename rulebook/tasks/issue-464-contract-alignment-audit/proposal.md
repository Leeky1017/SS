# Proposal: issue-464-contract-alignment-audit

## Why
Frontend/backend API contract drift is breaking Step3 UI rendering (e.g. `stage1_questions[].options` shape mismatch). We need a single source of truth and strict alignment across backend schemas/contracts and frontend types/consumers.

## What Changes
- Audit all mismatched fields for key `/v1` endpoints and legacy Desktop Pro consumption.
- Fix backend responses to match `src/api/schemas.py` contract shapes.
- Update frontend TypeScript types to match backend schemas exactly (no compatibility branches).
- Add/adjust tests as needed to prevent regression.

## Impact
- Affected specs: `openspec/specs/ss-frontend-backend-alignment/spec.md`, `openspec/specs/ss-frontend-desktop-pro/spec.md`, `openspec/specs/frontend-stata-proxy-extension/spec.md`
- Affected code: `src/api/`, `src/domain/`, `frontend/src/api/`, `frontend/src/features/step3/`, `assets/desktop_pro_*.js`
- Breaking change: YES (contract correction; frontend updated in lockstep)
- User benefit: Step3 clarification panels render correctly and contract drift is prevented by tests.
