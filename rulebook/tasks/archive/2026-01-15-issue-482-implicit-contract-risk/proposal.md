# Proposal: issue-482-implicit-contract-risk

## Why
The draft preview v1 contract currently relies on `Draft` extra fields for `stage1_questions` and
`open_unknowns`, which are injected via dict merge. This creates long-term drift risk between domain
models, API schemas, and generated frontend types.

## What Changes
- Make `Draft.stage1_questions` and `Draft.open_unknowns` explicit typed Pydantic fields in the
  domain model (no longer implicit extra dict payload).
- Update draft enrichment/patch flows to use typed fields directly.
- Explicitly mark currently-unused v1 inputs bundle/upload-sessions endpoints as internal in OpenAPI
  until frontend wiring lands.

## Impact
- Affected specs: `openspec/specs/ss-api-surface/spec.md`
- Affected code: `src/domain/models.py`, `src/domain/draft_v1_contract.py`, `src/domain/draft_service.py`, `src/api/inputs_bundle.py`, `src/api/inputs_upload_sessions.py`
- Breaking change: YES
- User benefit: Stable, typed Step3 contract fields and reduced implicit API surface risk
