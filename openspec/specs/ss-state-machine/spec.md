# Spec: ss-state-machine

## Purpose

Define the SS job state machine, allowed transitions, and idempotency strategy as domain logic so API/worker cannot diverge.

System-level, code-verified diagrams (Job/Plan/Run/UploadSession/Worker Queue) live in:
- `openspec/specs/ss-state-machine/state_machines.md`

## Vocabulary (v1)

### Status enum

- `created`
- `draft_ready`
- `confirmed`
- `queued`
- `running`
- `succeeded`
- `failed`

### Allowed transitions

- `created` → `draft_ready`
- `draft_ready` → `confirmed`
- `confirmed` → `queued`
- `queued` → `running`
- `running` → `succeeded`
- `running` → `failed`
- `failed` → `queued` (explicit retry)

### Idempotency key inputs

- MUST include `inputs.fingerprint` (empty string if missing).
- MUST include a normalized `requirement` (empty string if missing).
- MAY include a `plan_revision` (empty string if not applicable).

Normalization (v1): trim and collapse consecutive whitespace to a single space.

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

#### Scenario: Repeating the same transition is a no-op
- **WHEN** a request would transition a job to its current status
- **THEN** the operation succeeds without changing persisted state

### Requirement: Transition preconditions are explicit and validated

Each transition MUST have explicit preconditions (documented in `openspec/specs/ss-state-machine/state_machines.md`) and domain services MUST validate them before mutating state or enqueuing work.

When preconditions fail, the operation MUST fail with a structured error and MUST NOT partially advance job state.

#### Scenario: Failed validation does not partially advance state
- **WHEN** a transition fails validation (e.g., plan freeze blocked)
- **THEN** the job status is not advanced to `queued`

### Requirement: Transitions are concurrency-safe (optimistic versioning)

Job mutations MUST be persisted using the JobStore optimistic concurrency semantic (`job.version`), rejecting stale writes with a structured conflict (`error_code="JOB_VERSION_CONFLICT"`). See `openspec/specs/ss-job-store/spec.md`.

Domain services SHOULD treat version conflicts as recoverable by reloading and returning an idempotent response when the job already advanced.

#### Scenario: Concurrent transitions do not corrupt state
- **WHEN** two clients trigger the same transition concurrently
- **THEN** at most one write wins and the loser receives a structured conflict or the latest state
