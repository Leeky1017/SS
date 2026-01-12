# Spec: issue-407-state-machines

## Purpose

Create a canonical, code-verified set of Mermaid state machine diagrams for SS core components (Job/Plan/Run/UploadSession/Worker), including allowed transitions and the conditions that trigger each transition.

## Scope

- In scope:
  - Enumerating actual states as implemented in `src/` (domain models + services + worker).
  - Mermaid diagrams + short transition condition notes + code pointers.
  - System-level validation notes (dead states, deadlocks, missing error paths).
- Out of scope:
  - Refactoring state machines or changing semantics (unless a correctness bug is obvious and low-risk).

## Acceptance

- Job / Plan / Run / Upload Session / Worker state machines are documented.
- Each state machine includes Mermaid + transition condition notes + code pointers.
- Documentation is canonical under `openspec/specs/` (docs/ may only include pointers).

