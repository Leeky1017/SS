# Delta Spec: Phase 5.10 Finance (TK01-TK20)

## Purpose

Define checkable deltas for Phase 5.10: TK01–TK20 must retain Phase 4.10 runnability and additionally include best-practice review notes, stronger data-shape/missingness/outlier guardrails, and bilingual guidance without adding new external dependencies.

## Requirements

### Requirement: Each TK template MUST contain an explicit best-practice review record

TK templates MUST include a `SS_BEST_PRACTICE_REVIEW` block that documents key assumptions, diagnostics, and dependency notes.

#### Scenario: Review record is present and scoped to Phase 5.10
- **GIVEN** a TK do-template source file
- **WHEN** inspecting the header comments
- **THEN** a `SS_BEST_PRACTICE_REVIEW` block is present

### Requirement: Finance templates MUST emit explicit data guardrails (no silent failure)

Finance templates MUST validate required variables and data shape (panel/time keys when relevant), and MUST emit structured warnings for missingness and extreme values.

#### Scenario: Missingness/extremes are surfaced before analysis
- **GIVEN** a TK template with required variables
- **WHEN** inputs contain high missingness or extreme values
- **THEN** the template emits `SS_RC|...|severity=warn` with actionable context

