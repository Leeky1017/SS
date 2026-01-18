# Spec Delta: BE-006 Auxiliary column candidates

## Context

Draft preview needs to provide variable candidates across all uploaded datasets (primary + auxiliary) so the panel workflow can be completed.

## Requirements

- `GET /v1/jobs/{job_id}/draft/preview` remains backward compatible:
  - Keep `column_candidates: list[str]`.
  - Add `column_candidates_v2`, each item includes `dataset_key`, `role`, and `name`.
- `column_candidates` includes a best-effort union of column names across all datasets (duplicates removed).
- `column_candidates_v2` keeps per-dataset source info (allows duplicates across datasets).

## Scenarios

- When a job has a primary dataset and at least one auxiliary dataset, draft preview returns candidates for both.
- When an auxiliary dataset cannot be previewed, draft preview still returns primary candidates and does not fail the request.
