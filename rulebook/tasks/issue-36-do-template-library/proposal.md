# Proposal: issue-36-do-template-library

## Summary

- Vendor the legacy do-template library (`stata_service/tasks`) into SS as a read-only data asset (avoid `tasks/` naming).
- Add a domain port (`DoTemplateRepository`) and an infra filesystem implementation to load template + meta by `template_id`.
- Build an MVP execution loop: select template → fill placeholders → generate do-file → run via `StataRunner` → archive evidence artifacts.

## Changes

### ADDED

- Domain port for do-template loading.
- Infra filesystem repository reading the vendored library.
- Minimal template execution service/CLI wiring and tests.

### MODIFIED

- Specs/docs to clarify the template library contract and execution/artifact boundaries.

## Impact

- Affected specs: `openspec/specs/ss-do-template-library/spec.md`, `openspec/specs/ss-stata-runner/spec.md`
- Affected code: `src/domain/`, `src/infra/`, `tests/`
- Breaking change: NO (new capability)

