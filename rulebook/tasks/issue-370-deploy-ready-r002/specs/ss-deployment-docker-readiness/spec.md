# Delta Spec: DEPLOY-READY-R002 — do-template output format audit

## Scope
- Source of truth: `assets/stata_do_library/do/meta/*.meta.json` + sampled `assets/stata_do_library/do/*.do`.
- Formats tracked: `csv`, `xlsx`, `dta`, `docx`, `pdf`, `log`, `do`.
- Output contract reference: `openspec/specs/ss-job-contract/README.md` (artifact kinds + indexing rules).

## Requirements (delta)

### Requirement: Output format capability matrix is evidence-backed
- The repo MUST include an audit report grounded in the current `assets/stata_do_library/` inventory that:
  - summarizes declared outputs across templates,
  - highlights any observed mismatches between meta and template behavior, and
  - provides a format coverage matrix for `csv/xlsx/dta/docx/pdf/log/do`.

### Requirement: Word/PDF feasibility and gaps are explicit
- The audit MUST explicitly state:
  - whether any templates already generate `docx` and/or `pdf`,
  - the recommended implementation strategy (prefer Stata `putdocx` / `putpdf`), and
  - the delta required to make Word/PDF reports consistently available via a unified output formatter.

### Requirement: Artifact naming/kind consistency issues are actionable
- The audit MUST identify inconsistencies among:
  - file extensions in `outputs[].file`,
  - `outputs[].type` vocabulary, and
  - job-contract artifact `kind` vocabulary,
  and MUST propose normalization rules and priorities for DEPLOY-READY-R031.
