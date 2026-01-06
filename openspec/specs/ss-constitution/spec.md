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

The system MUST maintain these architectural contracts (details in `openspec/specs/ss-constitution/`):
- layering direction: `api -> domain -> ports <- infra` and a separate worker
- data contract: `job.json` v1 with `schema_version` and an artifacts index
- state machine + idempotency + concurrency strategy
- LLM Brain: schema-bound plan and auditable prompt/response artifacts with redaction
- Stata Runner: do-file generation, execution isolation, and archived outputs

#### Scenario: Changes reference the architecture contracts
- **WHEN** a new capability spec is added or modified
- **THEN** it aligns with the contracts above (or updates this constitution first)

### Requirement: Legacy reference policy is enforced

The legacy `stata_service` repository MAY be used for semantics and edge-case discovery, but implementations MUST NOT copy its architectural anti-patterns (dynamic proxies, global singletons, giant routes, swallowed exceptions).

#### Scenario: Legacy is used only as input
- **WHEN** reading legacy analysis docs
- **THEN** they are used as test vectors and semantic references, not as implementation templates

### Requirement: Delivery workflow is issue-gated and auditable

All changes MUST follow the SS delivery hard gates:
- GitHub Issue `#N` is the task ID
- branch name: `task/<N>-<slug>`
- every commit message contains `(#N)`
- PR body contains `Closes #N`
- PR includes run log: `openspec/_ops/task_runs/ISSUE-N.md`
- required checks are green: `ci` / `openspec-log-guard` / `merge-serial`
- auto-merge is enabled for PRs

#### Scenario: PR metadata and run log are enforced
- **WHEN** a PR is opened for Issue `#N`
- **THEN** `openspec-log-guard` fails if the branch/commit/PR body/run log rules are violated
