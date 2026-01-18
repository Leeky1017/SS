# Spec Delta: BE-005 Auxiliary file sheet selection

## Requirement: Support Excel sheet selection for any dataset

SS MUST allow selecting an Excel sheet for non-primary datasets (e.g. auxiliary inputs), persist the choice to the inputs manifest, and ensure downstream preview/candidate extraction uses the selected sheet.

The API SHOULD expose a stable dataset identifier (`dataset_key`) to address the dataset.

#### Scenario: Select auxiliary Excel sheet persists and takes effect
- **GIVEN** a job with an auxiliary Excel dataset that contains multiple sheets
- **WHEN** the client calls `POST /v1/jobs/{job_id}/inputs/datasets/{dataset_key}/sheet?sheet_name=<name>`
- **THEN** the selection is persisted to `inputs/manifest.json` for that dataset and later previews use that sheet

