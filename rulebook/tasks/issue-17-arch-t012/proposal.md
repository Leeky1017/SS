# Proposal: issue-17-arch-t012

## Summary

- Centralize job state transitions in domain logic to prevent route/worker divergence.
- Add stable idempotency key definition (fingerprint + normalized requirement + optional plan revision).
- Add unit tests covering legal/illegal transitions and idempotent repeats.

## Changes

### ADDED

- Domain state machine + idempotency helpers.

### MODIFIED

- Job services to use centralized guards and structured errors.
- Specs + tests to encode and protect the intended behavior.

