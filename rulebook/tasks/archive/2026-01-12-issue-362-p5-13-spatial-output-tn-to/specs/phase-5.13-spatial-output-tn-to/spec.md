# Spec: phase-5.13-spatial-output-tn-to

## Purpose

Define Phase 5.13 content enhancements for spatial (TN*) and output/reporting (TO*) templates: best-practice review records, Stata 18-native output tooling, stronger error handling, and bilingual comments.

## Requirements

### Requirement: Templates MUST include a Phase 5.13 best-practice review record

TN01–TN10 and TO01–TO08 MUST add a best-practice review block (EN/ZH) and emit a structured anchor:
- `SS_BP_REVIEW|issue=362|template_id=<ID>|ssc=<...>|output=<...>|policy=<...>`

#### Scenario: Review record is present and parsable
- **GIVEN** a TN*/TO* template updated in Phase 5.13
- **WHEN** scanning the template header
- **THEN** a Phase 5.13 review block exists
- **AND** `SS_BP_REVIEW` includes `issue` and `template_id`

### Requirement: TO* MUST provide a Stata 18-native output path (no SSC hard dependency)

TO01–TO08 MUST provide a Stata 18-native output mechanism (`collect`/`etable`/`putdocx`/`putexcel`) and MUST NOT require SSC packages (`esttab/outreg2/asdoc/table1_mc`) as hard dependencies.

#### Scenario: No hard dependency on SSC output packages
- **GIVEN** a clean Stata 18 environment with no SSC packages installed
- **WHEN** executing TO01–TO08
- **THEN** the template does not fail due to missing `esttab/outreg2/asdoc/table1_mc`

### Requirement: Error handling MUST be explicit (no silent failure)

Templates MUST not silently swallow failures; they MUST emit explicit `SS_RC` anchors and follow a clear policy:
- missing required inputs/variables → `severity=fail`
- optional/diagnostic steps may degrade → `severity=warn`

#### Scenario: Missing input file fails fast
- **GIVEN** `data.csv` is missing
- **WHEN** a template starts
- **THEN** it exits with `SS_RC|...|severity=fail` and emits `SS_TASK_END|...|status=fail`
