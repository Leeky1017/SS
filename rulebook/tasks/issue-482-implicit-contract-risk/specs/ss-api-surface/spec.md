# Spec delta: ss-api-surface (ISSUE-482)

## Scope
- Make v1 draft contract fields `stage1_questions` and `open_unknowns` explicit, typed domain fields.
- Explicitly mark currently-unused v1 inputs bundle/upload-sessions endpoints as internal in OpenAPI.

## Requirements

### R1: Draft has explicit typed v1 gating fields

#### Scenario: Domain draft fields are explicit and always present
- **GIVEN** `src/domain/models.py:Draft`
- **WHEN** draft enrichment runs for v1 jobs
- **THEN** `stage1_questions` and `open_unknowns` exist as typed Pydantic fields (may be empty lists)

### R2: Draft enrichment does not rely on extra dict payload for v1 gating fields

#### Scenario: Draft enrichment uses typed values
- **GIVEN** draft enrichment (`DraftService._enrich_draft`)
- **WHEN** `stage1_questions` / `open_unknowns` are populated
- **THEN** they are populated as typed values (not untyped extra dict merge)

### R3: Unused v1 upload endpoints are explicitly internal in OpenAPI

#### Scenario: Bundle + upload-sessions are marked internal until frontend wiring lands
- **GIVEN** the v1 OpenAPI schema
- **WHEN** a client inspects `/v1/jobs/{job_id}/inputs/bundle` or `/v1/jobs/{job_id}/inputs/upload-sessions`
- **THEN** these operations include `x-internal: true` in OpenAPI
