# Delta Spec: DEPLOY-READY-R030 — do-template data-shape meta remediation

## Scope
- Library: `assets/stata_do_library/do/*.do` + `assets/stata_do_library/do/meta/*.meta.json`.
- Focus:
  - machine-readable wide/long/panel signals in meta (`tags`)
  - rendering-time aliasing for panel id placeholders (`__ID_VAR__` vs `__PANELVAR__`)

## Requirements (delta)

### Requirement: Shape-sensitive templates declare data-shape tags
- Do-template meta MUST use `tags` to declare shape sensitivity:
  - `wide`: templates that require wide-style paired/multi-column inputs (e.g. before/after variables).
  - `long`: templates that require long/panel structure (entity/time rows) even if they also carry `panel`.
  - `panel`: templates that require `xtset`/panel operations (existing convention).
- Conversion templates MAY include both `wide` and `long` (e.g. reshape).

### Requirement: Rendering supports panel id placeholder aliases
- Placeholder rendering MUST treat `__ID_VAR__` and `__PANELVAR__` as aliases:
  - if either one is provided, templates that require the other MUST still render successfully.
- This MUST NOT break existing templates/meta that currently declare either placeholder.

### Requirement: Regression evidence exists for tags and aliasing
- The repo MUST include pytest coverage ensuring:
  - wide/long tags are present beyond the reshape template, and
  - aliasing allows `__ID_VAR__` to satisfy required `__PANELVAR__` (and vice versa when applicable).
