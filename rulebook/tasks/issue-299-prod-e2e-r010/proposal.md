# Proposal: issue-299-prod-e2e-r010

## Why
Production `/v1` plan+run hard-codes a stub `template_id` and does not load do-templates from the canonical library (`assets/stata_do_library/**`), blocking the audited production execution chain.

## What Changes
- Wire filesystem-backed `DoTemplateCatalog` + `DoTemplateRepository` into `/v1` via explicit dependency injection.
- Make plan freeze select a real do-template id from the library and include `template_params` in the plan.
- Make worker do-file generation render library templates via the injected repository.

## Impact
- Affected specs:
  - `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
  - `openspec/specs/ss-do-template-library/spec.md`
- Affected code:
  - `src/api/deps.py`
  - `src/domain/plan_service.py`
  - `src/domain/do_file_generator.py`
  - `src/domain/worker_service.py`
  - `src/worker.py`
- Breaking change: NO (internal wiring; `/v1` remains the surface)
- User benefit: `/v1` plan+run uses a real do-template from the library (no stub template ids).

