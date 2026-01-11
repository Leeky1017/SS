# Delta Spec: Phase 4.14 Panel + HLM (TP01-TP15, TQ01-TQ12)

## Purpose

Define the concrete, checkable deltas for Phase 4.14: panel and hierarchical-model templates `TP01`-`TP15` and `TQ01`-`TQ12` must be runnable under the Stata 18 smoke-suite harness with fixtures, emitting consistent pipe-delimited anchors and explicit failure diagnostics.

## Requirements

### Requirement: TP01-TP15 and TQ01-TQ12 MUST be runnable under the Stata 18 smoke-suite harness

#### Scenario: Each template runs with its fixture set
- **GIVEN** a TP/TQ-scoped smoke-suite manifest contains entries for `TP01`-`TP15` and `TQ01`-`TQ12`
- **WHEN** the smoke-suite harness stages fixtures and runs each template
- **THEN** every case finishes without runtime failures (`status!=failed`)

### Requirement: TP/TQ anchors MUST be normalized and machine-parseable

#### Scenario: No legacy `SS_*:` anchors within TP/TQ templates
- **WHEN** reading `result.log` for a TP/TQ template run
- **THEN** anchors use pipe-delimited `SS_*|k=v` format
- **AND** failures/warnings are recorded via `SS_RC|code=...|cmd=...|msg=...|severity=...`

### Requirement: Common panel + HLM failure modes MUST be explicit (warn/fail with SS_RC)

#### Scenario: xtset/mixed requirements and fragile assumptions are surfaced
- **GIVEN** inputs violate panel/HLM preconditions (panel identifiers/time, missingness, invalid grouping, non-convergence)
- **WHEN** the template validates inputs and runs model commands
- **THEN** it emits a structured `SS_RC|...|severity=<warn|fail>` with actionable context
- **AND** it does not silently proceed after `capture` without checking `_rc`
