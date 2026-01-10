# Delta Spec: Phase 5.9 Survival + Multivariate (TI01-TI11, TJ01-TJ06)

## Purpose

Define checkable deltas for Phase 5.9: TI01–TI11 and TJ01–TJ06 must retain Phase 4.9 runnability and additionally include best-practice review notes, stronger validation/diagnostics, and bilingual guidance without introducing new external dependencies.

## Requirements

### Requirement: Each TI/TJ template MUST contain an explicit best-practice review record

SS MUST include a `SS_BEST_PRACTICE_REVIEW` block in every TI01–TI11 and TJ01–TJ06 do-template.

#### Scenario: Review record is present and scoped to Phase 5.9
- **WHEN** inspecting a TI/TJ do-template source file
- **THEN** it contains a `SS_BEST_PRACTICE_REVIEW` block that documents:
  - PH assumption / competing risk applicability (as relevant)
  - dependency notes (SSC exceptions justified)
  - diagnostics and error-handling expectations

### Requirement: Survival templates MUST emit minimal diagnostics for key assumptions

Survival templates MUST attempt to emit minimal diagnostics for key modeling assumptions (e.g., PH tests for Cox models) and MUST not silently ignore diagnostic failures.

#### Scenario: Cox models emit PH test diagnostics when available
- **GIVEN** a Cox-based TI template (`TI05`, `TI06`, `TI07`) runs successfully
- **WHEN** diagnostics are executed
- **THEN** it attempts a PH assumption test (`estat phtest`) and records a structured warn on unavailability

### Requirement: Competing risks template MUST surface competing-event presence

TI04 MUST compute competing-event presence (`n_compete`) and MUST warn when competing events are absent.

#### Scenario: TI04 warns when competing events are absent
- **GIVEN** TI04 runs with a dataset
- **WHEN** competing-event counts are computed
- **THEN** it records `n_compete` and emits a structured warning if `n_compete==0`
