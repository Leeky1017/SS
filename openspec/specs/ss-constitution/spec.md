# Spec: ss-constitution

## Purpose

Define non-negotiable SS engineering boundaries (architecture + delivery), so future development treats OpenSpec as enforceable “law”.

## Requirements

### Requirement: Canonical docs live in OpenSpec

SS canonical project docs MUST live under `openspec/specs/`.
The `docs/` directory MUST only contain pointers and MUST NOT introduce conflicting rules.

#### Scenario: Canonical docs are under openspec
- **WHEN** browsing `openspec/specs/ss-constitution/`
- **THEN** constitutional docs exist and are treated as canonical

### Requirement: Repository hard constraints are binding

All implementations MUST follow repository hard constraints in `AGENTS.md`, including:
- explicit dependency injection
- no dynamic proxies / implicit forwarding
- no silent failures; structured errors and logs
- file/function size limits

#### Scenario: A PR follows hard constraints
- **WHEN** a new PR is reviewed
- **THEN** it does not introduce dynamic proxies or swallowed exceptions

### Requirement: Architecture contracts are binding

The system MUST maintain these architectural contracts (details in the SS contract specs):
- layering direction: `api -> domain -> ports <- infra-adapters` and a separate worker (`openspec/specs/ss-ports-and-services/spec.md`)
- data contract: `job.json` v1 with `schema_version` and an artifacts index (`openspec/specs/ss-job-contract/spec.md`)
- state machine + idempotency + concurrency strategy (`openspec/specs/ss-state-machine/spec.md`)
- LLM Brain: schema-bound plan and auditable prompt/response artifacts with redaction (`openspec/specs/ss-llm-brain/spec.md`)
- Worker/Queue: claim + run attempts + retry (`openspec/specs/ss-worker-queue/spec.md`)
- API contract: status + artifacts + run trigger (`openspec/specs/ss-api-surface/spec.md`)
- Stata Runner: do-file generation, execution isolation, and archived outputs (`openspec/specs/ss-stata-runner/spec.md`)
- Do template library integration (`openspec/specs/ss-do-template-library/spec.md`)
- observability baseline (`openspec/specs/ss-observability/spec.md`)
- security red lines (`openspec/specs/ss-security/spec.md`)
- delivery workflow gates (`openspec/specs/ss-delivery-workflow/spec.md`)

#### Scenario: Changes reference the architecture contracts
- **WHEN** a new capability spec is added or modified
- **THEN** it aligns with the contracts above (or updates this constitution first)

### Requirement: Layering distinguishes infra adapters from shared application infrastructure

The layering contract MUST distinguish between:
- **infra adapters**: concrete implementations that integrate external systems (e.g., S3 object store, Postgres job store, local Stata runner)
- **shared application infrastructure**: application-level shared primitives usable across layers (e.g., `src/infra/exceptions.py` `SSError` hierarchy; structured logging helpers)

Constraints:
- Domain layer MUST NOT depend on infra adapters.
- Domain layer MAY depend on shared application infrastructure.

#### Scenario: Domain uses shared application infrastructure without violating layering
- **WHEN** `src/domain/` imports `src/infra/exceptions.py` for `SSError`
- **THEN** it is treated as an allowed dependency on shared application infrastructure (not an infra adapter)

### Requirement: Legacy reference policy is enforced

The legacy `stata_service` repository MAY be used for semantics and edge-case discovery, but implementations MUST NOT copy its architectural anti-patterns (dynamic proxies, global singletons, giant routes, swallowed exceptions).

#### Scenario: Legacy is used only as input
- **WHEN** reading legacy analysis docs
- **THEN** they are used as test vectors and semantic references, not as implementation templates

### Requirement: Delivery workflow is issue-gated and auditable

All changes MUST follow the SS delivery hard gates defined by:
- `openspec/specs/ss-delivery-workflow/spec.md`

#### Scenario: PR metadata and run log are enforced
- **WHEN** a PR is opened for Issue `#N`
- **THEN** `openspec-log-guard` fails if the branch/commit/PR body/run log rules are violated
