# Spec: stata-service-legacy-analysis

## Purpose

Use `stata_service` only as a source of semantics and edge cases, while preventing legacy implementation patterns from becoming SS architecture.

## Requirements

### Requirement: Legacy analysis is input-only

Legacy analysis MUST only be used for:
- endpoint and state-machine semantics alignment
- enumerating edge cases and error paths
- deriving regression test vectors

#### Scenario: Legacy guides tests, not architecture
- **WHEN** implementing a new SS behavior
- **THEN** legacy is used to derive scenarios/tests, not to copy code structure

### Requirement: Legacy architectural anti-patterns are forbidden

SS implementations MUST NOT copy legacy patterns such as:
- dynamic proxies / implicit dependencies (`__getattr__`, module proxies, delayed imports)
- global singletons re-exported across layers
- giant route modules that mix auth, IO, business logic, and scheduling
- swallowed exceptions (logging + `pass`)

#### Scenario: Anti-patterns are rejected during review
- **WHEN** a PR introduces a forbidden pattern
- **THEN** it is blocked and the spec/architecture is corrected first

### Requirement: Legacy docs live in OpenSpec

Legacy analysis MUST live in OpenSpec and clearly state it is non-canonical.
The analysis content SHOULD be placed in `openspec/specs/stata-service-legacy-analysis/analysis.md`.

#### Scenario: Legacy analysis is discoverable and scoped
- **WHEN** browsing OpenSpec
- **THEN** `analysis.md` exists and is explicitly labeled as non-canonical

### Requirement: Legacy do templates are treated as a data asset (optional)

If SS reuses the legacy `stata_service/tasks/` folder as a do-template library, SS MUST treat it as a versioned data asset with an explicit contract and loader port, not as an architectural template.

#### Scenario: Do template reuse does not leak legacy architecture
- **WHEN** SS integrates legacy do templates
- **THEN** the integration follows `openspec/specs/ss-do-template-library/spec.md` and avoids copying legacy service structure
