# Delta Spec: ss-deployment-windows-non-docker (Issue #443)

Canonical spec: `openspec/specs/ss-deployment-windows-non-docker/spec.md`.

## Key Scenarios

#### Scenario: Docker deployment artifacts are archived
- **GIVEN** the repository is checked out
- **WHEN** an operator inspects the repository root
- **THEN** Docker deployment entrypoints are not present at repo root, and are archived under `legacy/docker/`

#### Scenario: Docker-only deployment specs are archived
- **GIVEN** the operator is reviewing deployment guidance
- **WHEN** an operator looks for Docker deployment guidance
- **THEN** Docker-only OpenSpecs are under `openspec/specs/archive/` (non-Docker deployment remains canonical)
