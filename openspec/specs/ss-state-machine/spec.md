# Spec: ss-state-machine

## Purpose

Define the SS job state machine, allowed transitions, and idempotency strategy as domain logic so API/worker cannot diverge.

## Requirements

### Requirement: State machine rules live in domain

State progression rules MUST be implemented as domain logic and MUST NOT be duplicated as route-level or worker-level ad-hoc `if/else`.

#### Scenario: State machine is treated as a domain contract
- **WHEN** implementing job state transitions
- **THEN** API and worker call a domain component that enforces allowed transitions

### Requirement: Illegal transitions fail with structured errors

Any illegal state transition MUST raise a structured error with `error_code` and MUST be logged with a stable event code.

#### Scenario: Illegal transition is rejected
- **WHEN** a transition is not in the allowed transition set
- **THEN** the operation fails with a structured error (not a silent failure)

### Requirement: Idempotency keys are defined and stable

Idempotency keys MUST include at least `inputs.fingerprint` and a normalized `requirement` (and MAY include a plan revision) so repeated requests do not create semantic conflicts.

#### Scenario: Repeated requests are idempotent
- **WHEN** the same logical request is repeated
- **THEN** the state machine produces the same resulting job identity/state without duplicating work

