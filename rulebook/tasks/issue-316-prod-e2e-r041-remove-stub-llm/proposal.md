# Proposal: issue-316-prod-e2e-r041-remove-stub-llm

## Why
Runtime stub LLM wiring (`SS_LLM_PROVIDER=stub` → `StubLLMClient`) is a production safety risk and violates the production-only execution chain requirement.

## What Changes
- Remove stub provider branch and stub client wiring from the runtime LLM client factory.
- Make `SS_LLM_PROVIDER=stub` explicitly invalid with a stable error code.
- Update tests to use injected fakes under `tests/**` (no runtime stub dependency).

## Impact
- Affected specs: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Affected code: `src/config.py`, `src/infra/llm_client_factory.py`, `src/domain/llm_client.py`, `tests/**`
- Breaking change: YES (runtime `stub` provider removed)
- User benefit: prevents silent non-production LLM behavior and improves auditability
