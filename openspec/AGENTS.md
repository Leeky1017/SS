# SS OpenSpec Handoff Manual

This file is the authoritative guide for maintaining SS as a **spec-first** project.

## Canonical rule

- All canonical project constraints live in `openspec/specs/` (especially `ss-constitution`).
- `docs/` is non-canonical and must only contain pointers (if any).

## Directory layout (OpenSpec official)

OpenSpec official CLI (`@fission-ai/openspec`) expects:

```text
openspec/
  project.md
  specs/<spec-id>/spec.md
  changes/<change-id>/{proposal.md,tasks.md,design.md?,specs/...}
  changes/archive/YYYY-MM-DD-<change-id>/
  _ops/
```

## SS delivery workflow (Issue + Rulebook + GitHub)

SS uses `$openspec-rulebook-github-delivery` as the delivery hard gate:

- Every change MUST be tracked by a GitHub Issue `#N`.
- Branch MUST be `task/<N>-<slug>`.
- All commits MUST include `(#N)`.
- PR body MUST include `Closes #N`.
- PR MUST include `openspec/_ops/task_runs/ISSUE-N.md`.

Rulebook tasks are the execution checklist:
- `rulebook/tasks/issue-<N>-<slug>/proposal.md`
- `rulebook/tasks/issue-<N>-<slug>/tasks.md`

## Spec writing (strict)

All active specs MUST pass:

```bash
openspec validate --specs --strict --no-interactive
```

Spec format baseline (required):
- `## Purpose`
- `## Requirements`
  - `### Requirement: ...`
    - `#### Scenario: ...`
      - `- **WHEN** ...`
      - `- **THEN** ...`

## Changes folder policy

`openspec/changes/` is reserved for cross-issue initiatives that need a dedicated change proposal.
If used, changes MUST also be mapped to a GitHub Issue and follow the same PR hard gates.

