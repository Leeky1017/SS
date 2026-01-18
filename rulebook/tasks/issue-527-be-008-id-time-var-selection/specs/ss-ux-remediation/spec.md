# Spec Delta: BE-008 ID/Time variable selection

## Context

Some templates require `__ID_VAR__` and `__TIME_VAR__` (or aliases). Users need a stable way to select these variables and have the selection applied during plan freeze.

## Requirements

- Draft preview returns `required_variables` entries for ID/TIME with candidate values.
- Plan freeze accepts user selections and uses them to populate required template params so `PLAN_FREEZE_MISSING_REQUIRED` is avoided when selections are provided.

## Scenarios

- When a user freezes a plan without providing ID/TIME selections, the system can surface a structured missing-required error.
- When a user provides ID/TIME selections, plan freeze succeeds and generated params include the selected values.
