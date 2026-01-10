# Spec Delta: PROD-E2E-R013

## Summary

In the worker execution chain, `stata.do` is generated only via the do-template library (no stub-only template path).

## Requirements

### Requirement: Do-template library is the single do-file source in worker runs

- The worker MUST render `stata.do` using template source + meta from the do-template library.
- The worker MUST NOT support the legacy `stub_descriptive_v1` do-file generation path.

### Requirement: Missing required template params fail fast with structured error

- When template meta declares a required parameter and it is missing from `template_params`,
  the worker MUST fail before invoking the Stata runner.
- The failure MUST return a structured error code (`DO_TEMPLATE_PARAM_MISSING`) and persist pre-run artifacts.

### Requirement: Successful run archives full template + run evidence

Successful run attempt artifacts MUST include:
- template evidence: `template/source.do`, `template/meta.json`, `template/params.json`
- `stata.do`, `stata.log`, `run.meta.json`
- do-template run meta: `do_template_run.meta.json`

