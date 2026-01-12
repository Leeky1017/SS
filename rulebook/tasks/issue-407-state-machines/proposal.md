# Proposal: issue-407-state-machines

## Why
SS has multiple interacting state machines (Job/Plan/Run/UploadSession/Worker). We need a single canonical, code-verified visualization to prevent divergence, detect dead states/locks early, and make maintenance safer.

## What Changes
- Extract the actual state enums + transition logic from the codebase.
- Document each core state machine as Mermaid diagrams with transition conditions and code pointers.
- Keep documentation canonical under `openspec/specs/` (and keep `docs/` pointer-only if used).

## Impact
- Affected specs: `openspec/specs/ss-state-machine/spec.md` (and/or a new OpenSpec under `openspec/specs/` if needed)
- Affected code: none expected (unless a clear state inconsistency is found)
- Breaking change: NO
- User benefit: faster debugging + less state-transition bugs + clearer onboarding/maintenance
