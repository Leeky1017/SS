# Spec delta: ss-api-surface (ISSUE-477)

## Scope
- Align frontend/back v1 contract types for plan freeze, plan, job query, and draft preview.
- Harden draft preview passthrough fields to avoid 500 from unexpected shapes.

## Requirements

### R1: FreezePlanRequest includes answers

#### Scenario: Client can submit freeze answers
- **GIVEN** `POST /v1/jobs/{job_id}/plan/freeze`
- **WHEN** a client submits `notes` and optional `answers`
- **THEN** `answers` is a JSON object mapping string keys to JSON values

### R2: PlanStepResponse.params is a JSON object of JSON values

#### Scenario: Params is serializable JSON
- **GIVEN** `GET /v1/jobs/{job_id}/plan`
- **WHEN** the API returns `steps[*].params`
- **THEN** `params` is a JSON object whose values are JSON values

### R3: GetJobResponse includes selected_template_id

#### Scenario: Template selection is observable
- **GIVEN** `GET /v1/jobs/{job_id}`
- **WHEN** a job has a selected template (or none)
- **THEN** the response includes `selected_template_id: string | null`

### R4: DraftPreview response status is stable and discriminated

#### Scenario: Pending and ready responses are distinguishable
- **GIVEN** `GET /v1/jobs/{job_id}/draft/preview`
- **WHEN** the draft is pending
- **THEN** `status` is exactly `"pending"`
- **WHEN** the draft is ready
- **THEN** `status` is exactly `"ready"`

### R5: Draft preview passthrough lists are sanitized

#### Scenario: Unexpected shapes do not crash the API
- **GIVEN** draft preview constructs an API response from `draft_dump`
- **WHEN** `data_quality_warnings`, `stage1_questions`, or `open_unknowns` are missing or not a list of objects
- **THEN** the API returns them as an empty list (and ignores non-object list items)
