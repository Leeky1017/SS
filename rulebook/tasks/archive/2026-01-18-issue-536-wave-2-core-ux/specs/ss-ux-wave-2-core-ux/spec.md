# Spec: ss-ux-wave-2-core-ux

## Purpose

Deliver Wave 2 core UX remediation: clearer layout hierarchy, explicit interaction feedback, and refresh-safe per-job input persistence.

## Requirements

### Requirement: Responsive main width MUST expand to 960px at >=1200px

On wide screens, the primary `<main>` content container MUST expand to a tool-appropriate max width of `960px` while preserving existing behavior on smaller viewports.

#### Scenario: Wide screen uses tool width
- **GIVEN** a user opens an SS job flow page
- **WHEN** viewport width is `>= 1200px`
- **THEN** the primary `<main>` content area uses a max width of `960px`

#### Scenario: Narrow screen stays usable
- **GIVEN** a user opens an SS job flow page
- **WHEN** viewport width is `< 1200px`
- **THEN** the layout keeps the existing narrow width behavior and remains usable

### Requirement: Table interaction affordances MUST be clearly visible

Table row hover/focus affordances MUST be clearly visible in both light and dark themes.

- Table row hover MUST be clearly visible in both light/dark themes.
- Hover/focus styling MUST NOT rely on color alone (focus styles remain visible).

### Requirement: Control styling MUST be consistent across browsers

Control states (default/focus/disabled) MUST be visually consistent across major browsers.

- `select` MUST have consistent baseline styling across major browsers, including focus/disabled states.
- Disabled buttons MUST look clearly disabled and MUST NOT show hover affordance.

### Requirement: Navigation feedback MUST be explicit and reversible

Navigation components (tabs/stepper) MUST provide immediate, understandable feedback and allow safe back-navigation without losing already-entered inputs.

- The stepper MUST display step names and the current position.
- Completed steps MUST be clickable to navigate back.
- Navigating back MUST NOT clear already entered user input (best-effort via persistence).
- Tab switching MUST provide immediate visual feedback and maintain predictable button states.

### Requirement: Loading UX MUST provide global and local feedback

The UI MUST expose request lifecycle state via a global busy indicator (for non-trivial waits) and local skeleton placeholders (where content shape is known).

- A global busy indicator MUST appear when any API request takes longer than `~300ms`.
- The global busy indicator MUST clear on success/failure/cancel.
- Step2/Step3 MUST provide skeleton placeholders for key content areas while loading.

### Requirement: localStorage persistence MUST be per-job and cleanable

Per-job local persistence MUST be stored under namespaced keys and MUST support explicit cleanup on confirm/reset/auth invalidation without deleting other jobs’ data.

- Step2 sheet selection MUST be persisted per job and restored after refresh (with a small “restored” hint).
- Step3 `variableCorrections` and `answers` MUST be persisted per job and restored after refresh (best-effort) with a “restored from local draft” hint.
- Persisted Step3 form state MUST be cleared after confirm success, and MUST be cleared on reset/unauthorized (401/403).
- Cleanup MUST NOT delete other jobs’ persisted data.

## Scenarios

#### Scenario: Step3 refresh-safe inputs

- **GIVEN** a user edits Step3 variable corrections and/or answers
- **WHEN** the page is refreshed
- **THEN** the inputs are restored from local draft and the UI indicates the restoration source

#### Scenario: Global busy indicator

- **GIVEN** a user triggers an API request
- **WHEN** the request lasts longer than ~300ms
- **THEN** a global busy indicator is shown and clears when the request ends
