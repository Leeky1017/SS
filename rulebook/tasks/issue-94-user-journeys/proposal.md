# Proposal: issue-94-user-journeys

## Why
We need user-journey tests to validate SS behavior the way a real user experiences it (state continuity, idempotency, recovery), beyond unit-level correctness.

## What Changes
- Add `tests/user_journeys/` fixtures for an API+worker journey.
- Implement A–D user journeys defined in `openspec/specs/ss-testing-strategy/README.md`.

## Impact
- Affected code: `tests/user_journeys/**`
- Breaking change: NO

