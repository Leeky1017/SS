# Proposal: issue-227-ss-inputs-upload-sessions

## Why
SS needs an upload pipeline that supports large inputs and high concurrency without routing file bytes through the API server, while still integrating with the existing `inputs/manifest.json` + `inputs/preview` loop and multi-tenant safety.

## What Changes
- Add new OpenSpec `openspec/specs/ss-inputs-upload-sessions/spec.md` defining:
  - bundle → upload-sessions (direct/multipart presigned) → finalize flow
  - fixed v1 API contracts and error codes
  - fixed file role enum + duplicate filename policy
  - fixed integration rules into job workspace `inputs/` + manifest schema_version=2 + bundle fingerprint
  - fixed security/auth constraints + configurable limits + observability/pressure-test gates
- Add 6 task cards (UPLOAD-C001–UPLOAD-C006) to split implementation into reviewable, parallelizable work.
- Add run log `openspec/_ops/task_runs/ISSUE-227.md` as delivery evidence.

## Impact
- Affected specs:
  - `openspec/specs/ss-inputs-upload-sessions/spec.md` (new)
- Affected code:
  - None (docs-only in this issue)
- Breaking change: NO
- User benefit: clear, testable contracts for scalable inputs uploads aligned with existing SS inputs + preview semantics.
