# Spec Delta: DEPLOY-READY-R031 — Unified Output Formatter + output_formats

## Requirement: output_formats is a job-level request field

- **GIVEN** a client submits/queues a job run
- **WHEN** the request includes `output_formats: string[]`
- **THEN** SS MUST persist `output_formats` into `job.json` for the worker to apply
- **AND** when omitted, SS MUST default to `["csv","log","do"]`.

## Requirement: Worker runs a unified post-run Output Formatter

- **GIVEN** a successful template execution run attempt
- **WHEN** the worker finishes archiving raw/template outputs
- **THEN** it MUST run a single unified Output Formatter step that:
  - reads the run’s raw artifacts (CSV/LOG/DO + archived template outputs),
  - produces the requested formats (at least `csv`, `xlsx`, `dta`, `docx`, `pdf`, `log`, `do`),
  - registers the produced artifacts in `job.json` artifacts index.

## Requirement: Artifact kind mapping is normalized for do-template outputs

- **GIVEN** do-template meta declares `outputs[].type` values such as `table`, `data`, `report`, `figure`/`graph`, `log`
- **WHEN** SS archives template outputs into the run artifacts index
- **THEN** it MUST map them into an explicit artifact kind vocabulary (no “unknown→log” fallback for `data`/`report`).

## Failure semantics

- If `output_formats` contains an unsupported format, the run MUST fail with a structured error:
  - `error_code: OUTPUT_FORMATS_INVALID`
- If Output Formatter cannot produce a requested format after a successful template run, the run MUST fail with:
  - `error_code: OUTPUT_FORMATTER_FAILED`

