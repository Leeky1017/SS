# Proposal: issue-409-layering-shared-app-infra

## Why
The SS specs currently treat any dependency on `src/infra/` as a layering violation, but in practice `src/domain/` imports `src/infra/exceptions.py` (`SSError` hierarchy) widely. These exceptions are application-level primitives (error_code/status_code), not external system adapters. Forcing an artificial split would add complexity without improving testability.

## What Changes
MODIFIED:
- `openspec/specs/ss-constitution/spec.md` to define infra adapters vs shared application infrastructure and adjust the layering constraint accordingly.
- `openspec/specs/ss-ports-and-services/spec.md` to allow domain depending on shared application infrastructure while still forbidding domain depending on infra adapters.

## Impact
- Affected specs: `openspec/specs/ss-constitution/spec.md`, `openspec/specs/ss-ports-and-services/spec.md`
- Affected code: None (spec alignment with existing practice)
- Breaking change: NO
- User benefit: Keeps domain testable while allowing pragmatic shared primitives (exceptions/logging) without spec churn.

